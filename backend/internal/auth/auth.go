// Package auth signs players in with a 6-digit code sent to their email.
package auth

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"math/big"
	"net"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kettik/internal/web"
)

// Same rules as mobile/lib/core/domain/auth.dart.
const (
	codeLife     = 10 * time.Minute
	resendAfter  = 60 * time.Second
	codeAttempts = 5

	codesPerEmailHour = 5
	codesPerIPHour    = 20
)

type Player struct {
	ID   string  `json:"id"`
	Name *string `json:"name"`
}

type Sender func(ctx context.Context, email, code string) error

type Service struct {
	db     *pgxpool.Pool
	secret []byte
	send   Sender
	limit  limiter
}

func New(db *pgxpool.Pool, secret []byte, send Sender) *Service {
	return &Service{db: db, secret: secret, send: send}
}

func (s *Service) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /auth/code", s.code)
	mux.HandleFunc("POST /auth/verify", s.verify)
	mux.HandleFunc("POST /auth/logout", s.Require(s.logout))
	mux.HandleFunc("GET /me", s.Require(s.me))
	mux.HandleFunc("POST /me", s.Require(s.rename))
}

func (s *Service) code(w http.ResponseWriter, r *http.Request) {
	var in struct{ Email string }
	if !web.ReadJSON(w, r, &in) {
		return
	}
	email, ok := parseEmail(in.Email)
	if !ok {
		web.Fail(w, http.StatusBadRequest, "bad_email", nil)
		return
	}
	if !s.limit.allow("ip:"+clientIP(r), codesPerIPHour) ||
		!s.limit.allow("email:"+email, codesPerEmailHour) {
		web.Fail(w, http.StatusTooManyRequests, "too_many", nil)
		return
	}
	code := sixDigits()
	// Within resendAfter the old code stays and nothing is sent.
	tag, err := s.db.Exec(r.Context(), `
		insert into login_codes (email, code_hash) values ($1, $2)
		on conflict (email) do update set code_hash = excluded.code_hash, sent_at = now(), attempts = 0
		where login_codes.sent_at < now() - make_interval(secs => $3)`,
		email, s.hash(email, code), resendAfter.Seconds())
	if err != nil {
		web.Internal(w, err)
		return
	}
	if tag.RowsAffected() == 1 {
		if err := s.send(r.Context(), email, code); err != nil {
			// Drop the code so the player can ask again at once.
			_, _ = s.db.Exec(context.WithoutCancel(r.Context()), `delete from login_codes where email = $1`, email)
			web.Internal(w, err)
			return
		}
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *Service) verify(w http.ResponseWriter, r *http.Request) {
	var in struct{ Email, Code string }
	if !web.ReadJSON(w, r, &in) {
		return
	}
	email, ok := parseEmail(in.Email)
	if !ok {
		web.Fail(w, http.StatusBadRequest, "bad_email", nil)
		return
	}
	ctx := r.Context()
	tx, err := s.db.Begin(ctx)
	if err != nil {
		web.Internal(w, err)
		return
	}
	defer tx.Rollback(ctx)

	var hash []byte
	var attempts int
	var expired bool
	err = tx.QueryRow(ctx, `
		select code_hash, attempts, sent_at < now() - make_interval(secs => $2)
		from login_codes where email = $1 for update`,
		email, codeLife.Seconds()).Scan(&hash, &attempts, &expired)
	if errors.Is(err, pgx.ErrNoRows) {
		web.Fail(w, http.StatusBadRequest, "code_burned", nil)
		return
	}
	if err != nil {
		web.Internal(w, err)
		return
	}
	if expired {
		s.burn(w, tx, email, "code_expired", nil)
		return
	}
	if !hmac.Equal(hash, s.hash(email, strings.TrimSpace(in.Code))) {
		left := codeAttempts - attempts - 1
		if left <= 0 {
			s.burn(w, tx, email, "code_burned", map[string]any{"attemptsLeft": 0})
			return
		}
		if _, err := tx.Exec(ctx, `update login_codes set attempts = attempts + 1 where email = $1`, email); err != nil {
			web.Internal(w, err)
			return
		}
		if err := tx.Commit(ctx); err != nil {
			web.Internal(w, err)
			return
		}
		web.Fail(w, http.StatusBadRequest, "wrong_code", map[string]any{"attemptsLeft": left})
		return
	}

	// Deleting the code under the row lock makes a repeated verify fail with code_burned.
	if _, err := tx.Exec(ctx, `delete from login_codes where email = $1`, email); err != nil {
		web.Internal(w, err)
		return
	}
	var p Player
	err = tx.QueryRow(ctx, `
		insert into players (email) values ($1)
		on conflict (email) do update set email = excluded.email
		returning id::text, name`, email).Scan(&p.ID, &p.Name)
	if err != nil {
		web.Internal(w, err)
		return
	}
	token := randomToken()
	if _, err := tx.Exec(ctx, `insert into sessions (token_hash, player_id) values ($1, $2)`, tokenHash(token), p.ID); err != nil {
		web.Internal(w, err)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		web.Internal(w, err)
		return
	}
	var player *Player
	if p.Name != nil {
		player = &p
	}
	web.WriteJSON(w, http.StatusOK, map[string]any{"token": token, "player": player})
}

func (s *Service) burn(w http.ResponseWriter, tx pgx.Tx, email, reason string, extra map[string]any) {
	ctx := context.Background()
	if _, err := tx.Exec(ctx, `delete from login_codes where email = $1`, email); err != nil {
		web.Internal(w, err)
		return
	}
	if err := tx.Commit(ctx); err != nil {
		web.Internal(w, err)
		return
	}
	web.Fail(w, http.StatusBadRequest, reason, extra)
}

type playerKey struct{}

// Require lets the request through only with a live session token.
func (s *Service) Require(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		token, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok || token == "" {
			web.Fail(w, http.StatusUnauthorized, "unauthorized", nil)
			return
		}
		var p Player
		err := s.db.QueryRow(r.Context(), `
			select p.id::text, p.name from sessions s join players p on p.id = s.player_id
			where s.token_hash = $1`, tokenHash(token)).Scan(&p.ID, &p.Name)
		if errors.Is(err, pgx.ErrNoRows) {
			web.Fail(w, http.StatusUnauthorized, "unauthorized", nil)
			return
		}
		if err != nil {
			web.Internal(w, err)
			return
		}
		next(w, r.WithContext(context.WithValue(r.Context(), playerKey{}, p)))
	}
}

// Me is the signed-in player; only valid behind Require.
func Me(ctx context.Context) Player { return ctx.Value(playerKey{}).(Player) }

func (s *Service) me(w http.ResponseWriter, r *http.Request) {
	web.WriteJSON(w, http.StatusOK, Me(r.Context()))
}

func (s *Service) rename(w http.ResponseWriter, r *http.Request) {
	var in struct{ Name string }
	if !web.ReadJSON(w, r, &in) {
		return
	}
	name, ok := parseName(in.Name)
	if !ok {
		web.Fail(w, http.StatusBadRequest, "bad_name", nil)
		return
	}
	p := Me(r.Context())
	if _, err := s.db.Exec(r.Context(), `update players set name = $2 where id = $1`, p.ID, name); err != nil {
		web.Internal(w, err)
		return
	}
	p.Name = &name
	web.WriteJSON(w, http.StatusOK, p)
}

func (s *Service) logout(w http.ResponseWriter, r *http.Request) {
	token := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	if _, err := s.db.Exec(r.Context(), `delete from sessions where token_hash = $1`, tokenHash(token)); err != nil {
		web.Internal(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// HMAC with a server secret, so a leaked table can't be brute-forced over the 10^6 codes.
func (s *Service) hash(email, code string) []byte {
	m := hmac.New(sha256.New, s.secret)
	m.Write([]byte(email + "\x00" + code))
	return m.Sum(nil)
}

func tokenHash(token string) []byte {
	h := sha256.Sum256([]byte(token))
	return h[:]
}

func randomToken() string {
	b := make([]byte, 32)
	_, _ = rand.Read(b)
	return base64.RawURLEncoding.EncodeToString(b)
}

func sixDigits() string {
	n, _ := rand.Int(rand.Reader, big.NewInt(1_000_000))
	return fmt.Sprintf("%06d", n)
}

var emailRe = regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)

func parseEmail(raw string) (string, bool) {
	email := strings.ToLower(strings.TrimSpace(raw))
	return email, len(email) <= 254 && emailRe.MatchString(email)
}

func parseName(raw string) (string, bool) {
	name := strings.Join(strings.Fields(raw), " ")
	n := utf8.RuneCountInString(name)
	return name, n >= 2 && n <= 40
}

// The API listens on loopback behind Caddy in prod (header_up X-Real-IP); only then is X-Real-IP trusted.
func clientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	if ip := net.ParseIP(host); ip != nil && ip.IsLoopback() {
		if real := r.Header.Get("X-Real-IP"); real != "" {
			return real
		}
	}
	return host
}

// shortcut: fixed hourly window kept in memory, reset on restart and per process; move to Postgres once there is more than one API instance.
type limiter struct {
	mu    sync.Mutex
	start time.Time
	hits  map[string]int
}

func (l *limiter) allow(key string, max int) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	if now := time.Now(); now.Sub(l.start) > time.Hour {
		l.start, l.hits = now, map[string]int{}
	}
	if l.hits[key] >= max {
		return false
	}
	l.hits[key]++
	return true
}
