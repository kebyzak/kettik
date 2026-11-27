package booking

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

type querier interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

const roomSelect = `
	select r.id::text, b.id::text, b.status, lower(b.during), upper(b.during), r.deadline, r.created_at,
	       r.rent, r.teams, r.level, r.organizer_id::text, f.id::text, v.name, v.address
	from rooms r
	join bookings b on b.id = r.booking_id
	join fields f on f.id = b.field_id
	join venues v on v.id = f.venue_id`

func loadRooms(ctx context.Context, q querier, where string, args ...any) ([]*room, error) {
	rows, err := q.Query(ctx, roomSelect+" "+where, args...)
	if err != nil {
		return nil, err
	}
	rooms, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (*room, error) {
		r := &room{}
		err := row.Scan(&r.ID, &r.BookingID, &r.Status, &r.Start, &r.End, &r.Deadline, &r.CreatedAt,
			&r.Rent, &r.Teams, &r.Level, &r.Organizer, &r.FieldID, &r.VenueName, &r.VenueAddress)
		return r, err
	})
	if err != nil || len(rooms) == 0 {
		return rooms, err
	}
	byID := map[string]*room{}
	ids := make([]string, len(rooms))
	for i, r := range rooms {
		byID[r.ID], ids[i] = r, r.ID
	}
	rows, err = q.Query(ctx, `
		select room_id::text, number, share, player_id::text, hold_id::text, until, payment_id::text,
		       leaving, repl_player_id::text, repl_hold_id::text, repl_until
		from places where room_id = any($1::uuid[]) order by room_id, number`, ids)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var id string
		var p place
		if err := rows.Scan(&id, &p.Number, &p.Share, &p.Player, &p.HoldID, &p.Until, &p.Payment,
			&p.Leaving, &p.ReplPlayer, &p.ReplHold, &p.ReplUntil); err != nil {
			return nil, err
		}
		byID[id].Places = append(byID[id].Places, p)
	}
	return rooms, rows.Err()
}

// lockRoom loads one room with its booking row locked: every change to a room
// and its confirmation serialize on that row. t is read after the lock.
func lockRoom(ctx context.Context, tx pgx.Tx, id string) (*room, time.Time, error) {
	rooms, err := loadRooms(ctx, tx, "where r.id = $1 for update of b", id)
	if err != nil {
		return nil, time.Time{}, err
	}
	if len(rooms) == 0 {
		return nil, time.Time{}, notFound
	}
	var t time.Time
	err = tx.QueryRow(ctx, `select clock_timestamp()`).Scan(&t)
	return rooms[0], t, err
}

func saveRoom(ctx context.Context, tx pgx.Tx, r *room) error {
	if !r.dirty {
		return nil
	}
	if _, err := tx.Exec(ctx, `update bookings set status = $2 where id = $1`, r.BookingID, r.Status); err != nil {
		return err
	}
	for _, p := range r.Places {
		_, err := tx.Exec(ctx, `
			update places set player_id = $3, hold_id = $4, until = $5, payment_id = $6, leaving = $7,
			       repl_player_id = $8, repl_hold_id = $9, repl_until = $10
			where room_id = $1 and number = $2`,
			r.ID, p.Number, p.Player, p.HoldID, p.Until, p.Payment, p.Leaving, p.ReplPlayer, p.ReplHold, p.ReplUntil)
		if err != nil {
			return err
		}
	}
	for _, f := range r.refunds {
		_, err := tx.Exec(ctx, `insert into refunds (payment_id, reason) values ($1, $2) on conflict do nothing`, f.Payment, f.Reason)
		if err != nil {
			return err
		}
	}
	return nil
}

// change runs fn on the locked room and saves what it did. A rejection still
// saves what time did to the room before it.
func change(ctx context.Context, db *pgxpool.Pool, id string, fn func(tx pgx.Tx, r *room, t time.Time) error) error {
	tx, err := db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	r, t, err := lockRoom(ctx, tx, id)
	if err != nil {
		return err
	}
	ruleErr := fn(tx, r, t)
	var rej Rejection
	if ruleErr != nil && !errors.As(ruleErr, &rej) {
		return ruleErr
	}
	if err := saveRoom(ctx, tx, r); err != nil {
		return err
	}
	if err := tx.Commit(ctx); err != nil {
		return err
	}
	return ruleErr
}

// Due lists rooms where time has changed something: the worker settles them.
func Due(ctx context.Context, db *pgxpool.Pool) ([]string, error) {
	rows, err := db.Query(ctx, `
		select r.id::text from rooms r join bookings b on b.id = r.booking_id
		where (b.status = 'held' and r.deadline <= now())
		   or exists (select 1 from places p where p.room_id = r.id and (
		          (p.payment_id is null and p.until <= now())
		       or p.repl_until <= now()
		       or (p.leaving and lower(b.during) - $1::interval <= now())))`,
		replaceCloseBeforeStart)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, pgx.RowTo[string])
}

// Settle saves what time has done to one room.
func Settle(ctx context.Context, db *pgxpool.Pool, id string) error {
	return change(ctx, db, id, func(_ pgx.Tx, r *room, t time.Time) error {
		r.settle(t)
		return nil
	})
}

// Cancel frees a booking's time. A game ends as cancelled and refunds every
// charge; a manual booking or a block just stops holding the field.
func Cancel(ctx context.Context, db *pgxpool.Pool, bookingID string) error {
	var roomID *string
	err := db.QueryRow(ctx, `select r.id::text from bookings b left join rooms r on r.booking_id = b.id where b.id = $1`, bookingID).Scan(&roomID)
	if err != nil {
		return err
	}
	if roomID == nil {
		_, err := db.Exec(ctx, `update bookings set status = 'cancelled' where id = $1 and status = 'confirmed'`, bookingID)
		return err
	}
	return change(ctx, db, *roomID, func(_ pgx.Tx, r *room, t time.Time) error {
		r.settle(t)
		if r.Status == held || r.Status == confirmed {
			r.end(cancelled, "cancelled")
		}
		return nil
	})
}
