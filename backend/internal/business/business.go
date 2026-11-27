// Package business is the API of kettik business, the venues' cabinet: venues,
// fields, tariffs and the day calendar. Every query joins business_members, so
// a member sees and changes only their own businesses.
package business

import (
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"kettik/internal/auth"
	"kettik/internal/booking"
	"kettik/internal/web"
)

type Service struct {
	db   *pgxpool.Pool
	auth *auth.Service
}

func New(db *pgxpool.Pool, a *auth.Service) *Service { return &Service{db: db, auth: a} }

func (s *Service) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /biz/me", s.auth.Require(s.me))
	mux.HandleFunc("GET /biz/venues", s.auth.Require(s.venues))
	mux.HandleFunc("POST /biz/venues", s.auth.Require(s.addVenue))
	mux.HandleFunc("PUT /biz/venues/{id}", s.auth.Require(s.editVenue))
	mux.HandleFunc("POST /biz/venues/{id}/fields", s.auth.Require(s.addField))
	mux.HandleFunc("PUT /biz/fields/{id}", s.auth.Require(s.editField))
	mux.HandleFunc("PUT /biz/fields/{id}/tariffs", s.auth.Require(s.setTariffs))
	mux.HandleFunc("GET /biz/venues/{id}/day", s.auth.Require(s.day))
	mux.HandleFunc("POST /biz/bookings", s.auth.Require(s.addBooking))
	mux.HandleFunc("DELETE /biz/bookings/{id}", s.auth.Require(s.cancel))
}

// The member's own rows: $1 is always the signed-in player.
const (
	myVenue = `select v.id from venues v join business_members m on m.business_id = v.business_id and m.player_id = $1 where v.id = $2`
	myField = `select f.id from fields f join venues v on v.id = f.venue_id
		join business_members m on m.business_id = v.business_id and m.player_id = $1 where f.id = $2`
)

func me(r *http.Request) string { return auth.Me(r.Context()).ID }

func (s *Service) me(w http.ResponseWriter, r *http.Request) {
	rows, err := s.db.Query(r.Context(), `
		select b.id::text, b.name from businesses b
		join business_members m on m.business_id = b.id
		where m.player_id = $1 order by b.name`, me(r))
	if err != nil {
		web.Internal(w, err)
		return
	}
	type biz struct {
		ID   string `json:"id"`
		Name string `json:"name"`
	}
	list, err := pgx.CollectRows(rows, pgx.RowToStructByPos[biz])
	if err != nil {
		web.Internal(w, err)
		return
	}
	web.WriteJSON(w, http.StatusOK, list)
}

type fieldJSON struct {
	ID      string           `json:"id"`
	Name    string           `json:"name"`
	Tariffs []booking.Tariff `json:"tariffs"`
}

type venueJSON struct {
	ID         string      `json:"id"`
	BusinessID string      `json:"businessId"`
	Name       string      `json:"name"`
	Address    string      `json:"address"`
	Fields     []fieldJSON `json:"fields"`
}

// venues lists the member's venues with their fields and tariffs.
func (s *Service) venues(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	rows, err := s.db.Query(ctx, `
		select v.id::text, v.business_id::text, v.name, v.address from venues v
		join business_members m on m.business_id = v.business_id and m.player_id = $1
		order by v.name`, me(r))
	if err != nil {
		web.Internal(w, err)
		return
	}
	venues, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (venueJSON, error) {
		v := venueJSON{Fields: []fieldJSON{}}
		err := row.Scan(&v.ID, &v.BusinessID, &v.Name, &v.Address)
		return v, err
	})
	if err != nil {
		web.Internal(w, err)
		return
	}
	for i := range venues {
		rows, err := s.db.Query(ctx, `select id::text, name from fields where venue_id = $1 order by name`, venues[i].ID)
		if err != nil {
			web.Internal(w, err)
			return
		}
		fields, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (fieldJSON, error) {
			var f fieldJSON
			err := row.Scan(&f.ID, &f.Name)
			return f, err
		})
		if err != nil {
			web.Internal(w, err)
			return
		}
		for j := range fields {
			if fields[j].Tariffs, err = booking.LoadTariffs(ctx, s.db, fields[j].ID); err != nil {
				web.Internal(w, err)
				return
			}
		}
		venues[i].Fields = fields
	}
	web.WriteJSON(w, http.StatusOK, venues)
}

func (s *Service) addVenue(w http.ResponseWriter, r *http.Request) {
	var in struct{ BusinessID, Name, Address string }
	if !web.ReadJSON(w, r, &in) {
		return
	}
	name, ok1 := text(in.Name, 80)
	address, ok2 := text(in.Address, 200)
	if !ok1 || !ok2 {
		web.Fail(w, http.StatusBadRequest, "bad_text", nil)
		return
	}
	var id string
	err := s.db.QueryRow(r.Context(), `
		insert into venues (business_id, name, address)
		select m.business_id, $3, $4 from business_members m where m.player_id = $1 and m.business_id = $2
		returning id::text`, me(r), in.BusinessID, name, address).Scan(&id)
	if err != nil {
		fail(w, err)
		return
	}
	web.WriteJSON(w, http.StatusCreated, map[string]string{"id": id})
}

func (s *Service) editVenue(w http.ResponseWriter, r *http.Request) {
	var in struct{ Name, Address string }
	if !web.ReadJSON(w, r, &in) {
		return
	}
	name, ok1 := text(in.Name, 80)
	address, ok2 := text(in.Address, 200)
	if !ok1 || !ok2 {
		web.Fail(w, http.StatusBadRequest, "bad_text", nil)
		return
	}
	s.exec(w, r, `update venues set name = $3, address = $4 where id in (`+myVenue+`)`, me(r), r.PathValue("id"), name, address)
}

func (s *Service) addField(w http.ResponseWriter, r *http.Request) {
	var in struct{ Name string }
	if !web.ReadJSON(w, r, &in) {
		return
	}
	name, ok := text(in.Name, 40)
	if !ok {
		web.Fail(w, http.StatusBadRequest, "bad_text", nil)
		return
	}
	var id string
	err := s.db.QueryRow(r.Context(), `
		insert into fields (venue_id, name) select id, $3 from (`+myVenue+`) v returning id::text`,
		me(r), r.PathValue("id"), name).Scan(&id)
	if err != nil {
		fail(w, err)
		return
	}
	web.WriteJSON(w, http.StatusCreated, map[string]string{"id": id})
}

func (s *Service) editField(w http.ResponseWriter, r *http.Request) {
	var in struct{ Name string }
	if !web.ReadJSON(w, r, &in) {
		return
	}
	name, ok := text(in.Name, 40)
	if !ok {
		web.Fail(w, http.StatusBadRequest, "bad_text", nil)
		return
	}
	s.exec(w, r, `update fields set name = $3 where id in (`+myField+`)`, me(r), r.PathValue("id"), name)
}

// setTariffs replaces the field's whole tariff list. Rooms keep the rent they
// were created with.
func (s *Service) setTariffs(w http.ResponseWriter, r *http.Request) {
	var in struct{ Tariffs []booking.Tariff }
	if !web.ReadJSON(w, r, &in) {
		return
	}
	if !booking.ValidTariffs(in.Tariffs) {
		web.Fail(w, http.StatusBadRequest, "bad_tariffs", nil)
		return
	}
	ctx := r.Context()
	tx, err := s.db.Begin(ctx)
	if err != nil {
		web.Internal(w, err)
		return
	}
	defer tx.Rollback(ctx)
	var fieldID string
	// The field's row lock serializes two saves of its tariffs.
	err = tx.QueryRow(ctx, `select id::text from fields where id in (`+myField+`) for update`, me(r), r.PathValue("id")).Scan(&fieldID)
	if err != nil {
		fail(w, err)
		return
	}
	if _, err := tx.Exec(ctx, `delete from tariffs where field_id = $1`, fieldID); err != nil {
		web.Internal(w, err)
		return
	}
	for _, t := range in.Tariffs {
		if _, err := tx.Exec(ctx, `insert into tariffs (field_id, days, from_min, to_min, price_per_hour) values ($1, $2, $3, $4, $5)`,
			fieldID, t.Days, t.From, t.To, t.Price); err != nil {
			web.Internal(w, err)
			return
		}
	}
	if err := tx.Commit(ctx); err != nil {
		web.Internal(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type bookingJSON struct {
	ID      string    `json:"id"`
	FieldID string    `json:"fieldId"`
	Start   time.Time `json:"start"`
	End     time.Time `json:"end"`
	Status  string    `json:"status"` // held (a game still funding) or confirmed
	Kind    string    `json:"kind"`   // game, manual, block
	Note    string    `json:"note"`
	Game    *gameJSON `json:"game,omitempty"`
}

type gameJSON struct {
	Organizer string    `json:"organizer"`
	Paid      int       `json:"paid"`
	Size      int       `json:"size"`
	Rent      int64     `json:"rent"` // tenge
	Deadline  time.Time `json:"deadline"`
	CreatedAt time.Time `json:"createdAt"`
}

// day lists every live booking holding a venue's time on one local date (YYYY-MM-DD).
func (s *Service) day(w http.ResponseWriter, r *http.Request) {
	day, err := time.ParseInLocation("2006-01-02", r.URL.Query().Get("date"), booking.Local)
	if err != nil {
		web.Fail(w, http.StatusBadRequest, "bad_range", nil)
		return
	}
	ctx := r.Context()
	var venueID string
	if err := s.db.QueryRow(ctx, `select id::text from (`+myVenue+`) v`, me(r), r.PathValue("id")).Scan(&venueID); err != nil {
		fail(w, err)
		return
	}
	rows, err := s.db.Query(ctx, `
		select b.id::text, b.field_id::text, lower(b.during), upper(b.during), b.status, b.kind, b.note,
		       r.id is not null, coalesce(o.name, ''),
		       (select count(*) from places p where p.room_id = r.id and p.payment_id is not null),
		       (select count(*) from places p where p.room_id = r.id),
		       coalesce(r.rent, 0) / 100, coalesce(r.deadline, b.created_at), coalesce(r.created_at, b.created_at)
		from bookings b
		join fields f on f.id = b.field_id
		left join rooms r on r.booking_id = b.id
		left join players o on o.id = r.organizer_id
		where f.venue_id = $1 and b.status in ('held', 'confirmed') and b.during && tstzrange($2, $3)
		order by lower(b.during)`, venueID, day, day.AddDate(0, 0, 1))
	if err != nil {
		web.Internal(w, err)
		return
	}
	list, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (bookingJSON, error) {
		var b bookingJSON
		var g gameJSON
		var isGame bool
		err := row.Scan(&b.ID, &b.FieldID, &b.Start, &b.End, &b.Status, &b.Kind, &b.Note,
			&isGame, &g.Organizer, &g.Paid, &g.Size, &g.Rent, &g.Deadline, &g.CreatedAt)
		if isGame {
			b.Game = &g
		}
		return b, err
	})
	if err != nil {
		web.Internal(w, err)
		return
	}
	web.WriteJSON(w, http.StatusOK, map[string]any{"bookings": list})
}

// addBooking takes a field's time for an offline client (manual) or closes it
// (block). The database refuses an overlap with any live booking, kettik's included.
func (s *Service) addBooking(w http.ResponseWriter, r *http.Request) {
	var in struct {
		FieldID    string
		Start, End time.Time
		Kind, Note string
	}
	if !web.ReadJSON(w, r, &in) {
		return
	}
	note, _ := text(in.Note, 200)
	if (in.Kind != "manual" && in.Kind != "block") || !booking.OnGrid(in.Start) || !booking.OnGrid(in.End) ||
		!in.Start.Before(in.End) || in.End.Sub(in.Start) > 24*time.Hour {
		web.Fail(w, http.StatusBadRequest, "bad_booking", nil)
		return
	}
	var id string
	err := s.db.QueryRow(r.Context(), `
		insert into bookings (field_id, during, status, kind, note)
		select id, tstzrange($3, $4), 'confirmed', $5, $6 from (`+myField+`) f returning id::text`,
		me(r), in.FieldID, in.Start, in.End, in.Kind, note).Scan(&id)
	if err != nil {
		fail(w, err)
		return
	}
	web.WriteJSON(w, http.StatusCreated, map[string]string{"id": id})
}

// cancel frees a booking; a kettik game is cancelled with a refund to every player who paid.
func (s *Service) cancel(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	var id string
	err := s.db.QueryRow(ctx, `
		select b.id::text from bookings b
		join fields f on f.id = b.field_id join venues v on v.id = f.venue_id
		join business_members m on m.business_id = v.business_id and m.player_id = $1
		where b.id = $2`,
		me(r), r.PathValue("id")).Scan(&id)
	if err != nil {
		fail(w, err)
		return
	}
	if err := booking.Cancel(ctx, s.db, id); err != nil {
		web.Internal(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// exec runs one update of the member's row: no row means not theirs or gone.
func (s *Service) exec(w http.ResponseWriter, r *http.Request, sql string, args ...any) {
	tag, err := s.db.Exec(r.Context(), sql, args...)
	if err != nil {
		fail(w, err)
		return
	}
	if tag.RowsAffected() == 0 {
		web.Fail(w, http.StatusNotFound, "not_found", nil)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func fail(w http.ResponseWriter, err error) {
	var pgErr *pgconn.PgError
	switch {
	case errors.Is(err, pgx.ErrNoRows), errors.As(err, &pgErr) && pgErr.Code == "22P02":
		// not the member's, gone, or a malformed uuid
		web.Fail(w, http.StatusNotFound, "not_found", nil)
	case errors.As(err, &pgErr) && pgErr.Code == "23P01":
		web.Fail(w, http.StatusConflict, "slot_taken", nil)
	default:
		web.Internal(w, err)
	}
}

// text trims and checks a name or an address: 1 to max characters.
func text(raw string, max int) (string, bool) {
	t := strings.Join(strings.Fields(raw), " ")
	n := utf8.RuneCountInString(t)
	return t, n >= 1 && n <= max
}
