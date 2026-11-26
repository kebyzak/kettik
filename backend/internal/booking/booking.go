package booking

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"kettik/internal/auth"
	"kettik/internal/web"
)

// Same limits as mobile/lib/features/create/create_screen.dart.
const (
	minSize = 6
	maxSize = 22
)

var durations = map[time.Duration]bool{60 * time.Minute: true, 90 * time.Minute: true, 120 * time.Minute: true}

type Service struct {
	db   *pgxpool.Pool
	auth *auth.Service
}

func New(db *pgxpool.Pool, a *auth.Service) *Service { return &Service{db: db, auth: a} }

// Routes adds the player API. dev also adds a fake provider that marks payments paid.
func (s *Service) Routes(mux *http.ServeMux, dev bool) {
	mux.HandleFunc("GET /venues", s.venues)
	mux.HandleFunc("GET /fields/{id}/busy", s.busy)
	mux.HandleFunc("GET /games", s.feed)
	mux.HandleFunc("GET /games/{id}", s.game)
	mux.HandleFunc("POST /games", s.auth.Require(s.create))
	mux.HandleFunc("GET /me/games", s.auth.Require(s.myGames))
	mux.HandleFunc("POST /games/{id}/places/{n}/hold", s.auth.Require(s.act((*room).hold)))
	mux.HandleFunc("DELETE /games/{id}/places/{n}/hold", s.auth.Require(s.act((*room).release)))
	mux.HandleFunc("POST /games/{id}/places/{n}/leave", s.auth.Require(s.act((*room).leave)))
	mux.HandleFunc("POST /games/{id}/places/{n}/stay", s.auth.Require(s.act((*room).stay)))
	mux.HandleFunc("POST /games/{id}/places/{n}/pay", s.auth.Require(s.pay))
	if dev {
		mux.HandleFunc("POST /dev/payments/{id}/succeed", s.devSucceed)
	}
}

func (s *Service) venues(w http.ResponseWriter, r *http.Request) {
	rows, err := s.db.Query(r.Context(), `
		select v.id::text, v.name, v.address,
		       json_agg(json_build_object('id', f.id, 'name', f.name, 'pricePerHour', f.price_per_hour) order by f.name)
		from venues v join fields f on f.venue_id = v.id
		group by v.id order by v.name`)
	if err != nil {
		web.Internal(w, err)
		return
	}
	type venue struct {
		ID      string `json:"id"`
		Name    string `json:"name"`
		Address string `json:"address"`
		Fields  []struct {
			ID           string `json:"id"`
			Name         string `json:"name"`
			PricePerHour int    `json:"pricePerHour"`
		} `json:"fields"`
	}
	list, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (venue, error) {
		var v venue
		err := row.Scan(&v.ID, &v.Name, &v.Address, &v.Fields)
		return v, err
	})
	if err != nil {
		web.Internal(w, err)
		return
	}
	web.WriteJSON(w, http.StatusOK, list)
}

// busy lists the field's taken intervals in [from, to), for picking a slot.
func (s *Service) busy(w http.ResponseWriter, r *http.Request) {
	from, err1 := time.Parse(time.RFC3339, r.URL.Query().Get("from"))
	to, err2 := time.Parse(time.RFC3339, r.URL.Query().Get("to"))
	if err1 != nil || err2 != nil || !from.Before(to) || to.Sub(from) > 31*24*time.Hour {
		web.Fail(w, http.StatusBadRequest, "bad_range", nil)
		return
	}
	rows, err := s.db.Query(r.Context(), `
		select lower(during), upper(during) from bookings
		where field_id = $1 and status in ('held', 'confirmed') and during && tstzrange($2, $3)
		order by lower(during)`, r.PathValue("id"), from, to)
	if err != nil {
		web.Internal(w, err)
		return
	}
	type span struct {
		Start time.Time `json:"start"`
		End   time.Time `json:"end"`
	}
	list, err := pgx.CollectRows(rows, pgx.RowToStructByPos[span])
	if err != nil {
		web.Internal(w, err)
		return
	}
	web.WriteJSON(w, http.StatusOK, list)
}

func (s *Service) create(w http.ResponseWriter, r *http.Request) {
	me, ok := named(w, r)
	if !ok {
		return
	}
	var in struct {
		FieldID    string
		Start, End time.Time
		Size       int
		Teams      int
		Level      string
	}
	if !web.ReadJSON(w, r, &in) {
		return
	}
	if !durations[in.End.Sub(in.Start)] || in.Size < minSize || in.Size > maxSize ||
		(in.Teams != 2 && in.Teams != 3) || in.Size < 2*in.Teams ||
		(in.Level != "casual" && in.Level != "middle" && in.Level != "strong") {
		web.Fail(w, http.StatusBadRequest, "bad_game", nil)
		return
	}
	ctx := r.Context()
	tx, err := s.db.Begin(ctx)
	if err != nil {
		web.Internal(w, err)
		return
	}
	defer tx.Rollback(ctx)

	var price int64
	var t time.Time
	err = tx.QueryRow(ctx, `select price_per_hour, clock_timestamp() from fields where id = $1`, in.FieldID).Scan(&price, &t)
	if errors.Is(err, pgx.ErrNoRows) {
		s.reject(w, notFound)
		return
	}
	if err != nil {
		web.Internal(w, err)
		return
	}
	deadline := fundingDeadline(t, in.Start)
	if !t.Before(deadline) {
		s.reject(w, tooLate)
		return
	}
	// The rent is fixed now; later tariff changes don't touch this room.
	rentTenge := price * int64(in.End.Sub(in.Start)/time.Minute) / 60

	var bookingID, roomID string
	err = tx.QueryRow(ctx, `
		insert into bookings (field_id, during, status) values ($1, tstzrange($2, $3), 'held') returning id::text`,
		in.FieldID, in.Start, in.End).Scan(&bookingID)
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23P01" {
		s.reject(w, slotTaken)
		return
	}
	if err != nil {
		web.Internal(w, err)
		return
	}
	err = tx.QueryRow(ctx, `
		insert into rooms (booking_id, organizer_id, rent, teams, level, created_at, deadline)
		values ($1, $2, $3, $4, $5, $6, $7) returning id::text`,
		bookingID, me, rentTenge*100, in.Teams, in.Level, t, deadline).Scan(&roomID)
	if err != nil {
		web.Internal(w, err)
		return
	}
	for i, share := range splitRent(rentTenge, in.Size) {
		if _, err := tx.Exec(ctx, `insert into places (room_id, number, share) values ($1, $2, $3)`, roomID, i+1, share*100); err != nil {
			web.Internal(w, err)
			return
		}
	}
	// The organizer reserves place 1 and pays for it like everyone else.
	rm, _, err := lockRoom(ctx, tx, roomID)
	if err == nil {
		err = rm.hold(1, me, t)
	}
	if err == nil {
		err = saveRoom(ctx, tx, rm)
	}
	if err == nil {
		err = tx.Commit(ctx)
	}
	if err != nil {
		web.Internal(w, err)
		return
	}
	s.writeGame(w, r.Context(), roomID, http.StatusCreated)
}

func (s *Service) feed(w http.ResponseWriter, r *http.Request) {
	rooms, err := loadRooms(r.Context(), s.db, `
		where b.status in ('held', 'confirmed') and lower(b.during) > now()
		order by lower(b.during) limit 200`)
	if err != nil {
		web.Internal(w, err)
		return
	}
	t := time.Now()
	var open []*room
	for _, rm := range rooms {
		rm.settle(t)
		if rm.Status == held || rm.seeksReplacement() {
			open = append(open, rm)
		}
	}
	s.writeGames(w, r.Context(), open)
}

func (s *Service) myGames(w http.ResponseWriter, r *http.Request) {
	rooms, err := loadRooms(r.Context(), s.db, `
		where exists (select 1 from places p where p.room_id = r.id and $1 in (p.player_id, p.repl_player_id))
		order by lower(b.during) desc limit 100`, auth.Me(r.Context()).ID)
	if err != nil {
		web.Internal(w, err)
		return
	}
	t := time.Now()
	for _, rm := range rooms {
		rm.settle(t)
	}
	s.writeGames(w, r.Context(), rooms)
}

func (s *Service) game(w http.ResponseWriter, r *http.Request) {
	s.writeGame(w, r.Context(), r.PathValue("id"), http.StatusOK)
}

// act runs one place rule for the signed-in player and answers the game.
func (s *Service) act(rule func(*room, int, string, time.Time) error) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		me, ok := named(w, r)
		if !ok {
			return
		}
		n, err := strconv.Atoi(r.PathValue("n"))
		if err != nil {
			s.reject(w, notFound)
			return
		}
		id := r.PathValue("id")
		err = change(r.Context(), s.db, id, func(_ pgx.Tx, rm *room, t time.Time) error {
			return rule(rm, n, me, t)
		})
		if err != nil {
			s.fail(w, err)
			return
		}
		s.writeGame(w, r.Context(), id, http.StatusOK)
	}
}

// pay opens the payment attempt for the player's reservation, or returns the
// one already open. A new attempt opens only after a confirmed failure.
func (s *Service) pay(w http.ResponseWriter, r *http.Request) {
	me, ok := named(w, r)
	if !ok {
		return
	}
	n, err := strconv.Atoi(r.PathValue("n"))
	if err != nil {
		s.reject(w, notFound)
		return
	}
	id := r.PathValue("id")
	var payment struct {
		ID     string `json:"id"`
		Amount int64  `json:"amount"` // tiyn
		Status string `json:"status"`
	}
	err = change(r.Context(), s.db, id, func(tx pgx.Tx, rm *room, t time.Time) error {
		holdID, share, err := rm.holdOf(n, me, t)
		if err != nil {
			return err
		}
		ctx := r.Context()
		// The booking row lock serializes attempts for the same hold.
		err = tx.QueryRow(ctx, `
			select id::text, amount, status from payments
			where hold_id = $1 and status <> 'failed'`, holdID).Scan(&payment.ID, &payment.Amount, &payment.Status)
		if errors.Is(err, pgx.ErrNoRows) {
			err = tx.QueryRow(ctx, `
				insert into payments (room_id, number, hold_id, player_id, amount)
				values ($1, $2, $3, $4, $5) returning id::text, amount, status`,
				rm.ID, n, holdID, me, share).Scan(&payment.ID, &payment.Amount, &payment.Status)
		}
		return err
	})
	if err != nil {
		s.fail(w, err)
		return
	}
	// shortcut: no provider yet, so no payment page url; Halyk ePay comes next (docs/booking-mvp.md).
	web.WriteJSON(w, http.StatusOK, payment)
}

// Credit settles a provider-confirmed charge exactly once. The caller has
// already checked the charge with the provider; amount is in tiyn.
func (s *Service) Credit(ctx context.Context, paymentID string, amount int64) error {
	var roomID string
	if err := s.db.QueryRow(ctx, `select room_id::text from payments where id = $1`, paymentID).Scan(&roomID); err != nil {
		return err
	}
	// Marking the payment and settling the place share one transaction, so a
	// repeated event finds it succeeded and changes nothing.
	return change(ctx, s.db, roomID, func(tx pgx.Tx, rm *room, t time.Time) error {
		var holdID, status string
		var want int64
		err := tx.QueryRow(ctx, `select hold_id::text, status, amount from payments where id = $1 for update`, paymentID).
			Scan(&holdID, &status, &want)
		if err != nil {
			return err
		}
		if status == "succeeded" {
			return nil
		}
		if amount != want {
			return errors.New("payment amount mismatch: " + paymentID)
		}
		if _, err := tx.Exec(ctx, `update payments set status = 'succeeded' where id = $1`, paymentID); err != nil {
			return err
		}
		rm.credit(paymentID, holdID, t)
		return nil
	})
}

func (s *Service) devSucceed(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var amount int64
	if err := s.db.QueryRow(r.Context(), `select amount from payments where id = $1`, id).Scan(&amount); err != nil {
		s.reject(w, notFound)
		return
	}
	if err := s.Credit(r.Context(), id, amount); err != nil {
		s.fail(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func named(w http.ResponseWriter, r *http.Request) (string, bool) {
	me := auth.Me(r.Context())
	if me.Name == nil {
		web.Fail(w, http.StatusForbidden, "no_name", nil)
		return "", false
	}
	return me.ID, true
}

func (s *Service) fail(w http.ResponseWriter, err error) {
	var rej Rejection
	var pgErr *pgconn.PgError
	switch {
	case errors.As(err, &rej):
		s.reject(w, rej)
	case errors.As(err, &pgErr) && pgErr.Code == "22P02", errors.Is(err, pgx.ErrNoRows):
		// a malformed uuid in the path
		s.reject(w, notFound)
	default:
		web.Internal(w, err)
	}
}

func (s *Service) reject(w http.ResponseWriter, rej Rejection) {
	status := http.StatusConflict
	if rej == notFound {
		status = http.StatusNotFound
	}
	web.Fail(w, status, string(rej), nil)
}
