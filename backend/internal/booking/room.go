// Package booking runs rooms and their bookings by docs/booking-mvp.md.
// The rules mirror mobile/lib/core/domain/game.dart.
package booking

import (
	"time"

	"github.com/google/uuid"
)

const (
	placeHold               = 10 * time.Minute
	fundingWindow           = 24 * time.Hour
	fundingCloseBeforeStart = 2 * time.Hour
	replaceCloseBeforeStart = 2 * time.Hour
)

// Rejection is a booking rule saying no; the API answers it with 409.
type Rejection string

func (r Rejection) Error() string { return string(r) }

const (
	placeTaken    Rejection = "place_taken"
	alreadyInGame Rejection = "already_in_game"
	fundingClosed Rejection = "funding_closed"
	holdExpired   Rejection = "hold_expired"
	notHeld       Rejection = "not_held"
	cannotLeave   Rejection = "cannot_leave"
	tooLate       Rejection = "too_late"
	slotTaken     Rejection = "slot_taken"
	closed        Rejection = "closed"
	notFound      Rejection = "not_found"
)

// Booking statuses; the app calls held "funding".
const (
	held      = "held"
	confirmed = "confirmed"
	expired   = "expired"
	cancelled = "cancelled"
)

type place struct {
	Number     int
	Share      int64
	Player     *string
	HoldID     *string
	Until      *time.Time
	Payment    *string
	Leaving    bool
	ReplPlayer *string
	ReplHold   *string
	ReplUntil  *time.Time
}

func (p *place) free() {
	*p = place{Number: p.Number, Share: p.Share}
}

func (p *place) clearRepl() {
	p.ReplPlayer, p.ReplHold, p.ReplUntil = nil, nil, nil
}

type refund struct{ Payment, Reason string }

type room struct {
	ID, BookingID, Organizer, Status, Level string
	FieldID, VenueName, VenueAddress        string
	Start, End, Deadline, CreatedAt         time.Time
	Rent                                    int64
	Teams                                   int
	Places                                  []place

	// queued in this transaction
	refunds []refund
	dirty   bool
}

func fundingDeadline(createdAt, start time.Time) time.Time {
	return earlier(createdAt.Add(fundingWindow), start.Add(-fundingCloseBeforeStart))
}

func (r *room) replaceDeadline() time.Time { return r.Start.Add(-replaceCloseBeforeStart) }

func (r *room) seeksReplacement() bool {
	if r.Status != confirmed {
		return false
	}
	for _, p := range r.Places {
		if p.Leaving {
			return true
		}
	}
	return false
}

func (r *room) numberOf(player string) int {
	for _, p := range r.Places {
		if is(p.Player, player) || is(p.ReplPlayer, player) {
			return p.Number
		}
	}
	return 0
}

func (r *room) place(number int) (*place, error) {
	if number < 1 || number > len(r.Places) {
		return nil, notFound
	}
	return &r.Places[number-1], nil
}

// settle applies everything time has done to the room by t.
func (r *room) settle(t time.Time) {
	replacing := t.Before(r.replaceDeadline())
	for i := range r.Places {
		p := &r.Places[i]
		if p.ReplUntil != nil && !t.Before(*p.ReplUntil) {
			p.clearRepl()
			r.dirty = true
		}
		if p.Player != nil && p.Payment == nil && !t.Before(*p.Until) {
			p.free()
			r.dirty = true
		}
		// No replacement in time: the leaver keeps the place and the charge.
		if p.Leaving && !replacing {
			p.Leaving = false
			r.dirty = true
		}
	}
	if r.Status == held && !t.Before(r.Deadline) {
		r.end(expired, "expired")
	}
}

// end closes the room and refunds every charge in it.
func (r *room) end(status, reason string) {
	r.Status = status
	r.dirty = true
	for i := range r.Places {
		p := &r.Places[i]
		if p.Payment != nil {
			r.refunds = append(r.refunds, refund{*p.Payment, reason})
		}
		if p.Payment == nil {
			p.free()
		}
		p.clearRepl()
		p.Leaving = false
	}
}

func (r *room) hold(number int, player string, t time.Time) error {
	r.settle(t)
	if r.Status != held && r.Status != confirmed {
		return fundingClosed
	}
	if r.numberOf(player) != 0 {
		return alreadyInGame
	}
	p, err := r.place(number)
	if err != nil {
		return err
	}
	id := uuid.NewString()
	if r.Status == held {
		if p.Player != nil {
			return placeTaken
		}
		until := earlier(t.Add(placeHold), r.Deadline)
		p.Player, p.HoldID, p.Until = &player, &id, &until
	} else {
		if !p.Leaving || p.ReplPlayer != nil {
			return placeTaken
		}
		until := earlier(t.Add(placeHold), r.replaceDeadline())
		p.ReplPlayer, p.ReplHold, p.ReplUntil = &player, &id, &until
	}
	r.dirty = true
	return nil
}

// holdOf is the player's live reservation at number: its id and the price.
func (r *room) holdOf(number int, player string, t time.Time) (string, int64, error) {
	r.settle(t)
	p, err := r.place(number)
	if err != nil {
		return "", 0, err
	}
	switch {
	case is(p.Player, player) && p.Payment == nil:
		return *p.HoldID, p.Share, nil
	case is(p.ReplPlayer, player):
		return *p.ReplHold, p.Share, nil
	}
	return "", 0, notHeld
}

// credit settles a successful charge. A charge that no longer has its
// reservation is refunded and doesn't bring the place back.
func (r *room) credit(payment, holdID string, t time.Time) {
	r.settle(t)
	r.dirty = true
	if r.Status == held || r.Status == confirmed {
		for i := range r.Places {
			p := &r.Places[i]
			switch {
			case p.Payment == nil && is(p.HoldID, holdID):
				p.Payment, p.HoldID, p.Until = &payment, nil, nil
				if r.Status == held && r.paidCount() == len(r.Places) {
					r.Status = confirmed
				}
				return
			case is(p.ReplHold, holdID):
				r.refunds = append(r.refunds, refund{*p.Payment, "replaced"})
				p.Player, p.Payment, p.Leaving = p.ReplPlayer, &payment, false
				p.HoldID, p.Until = nil, nil
				p.clearRepl()
				return
			}
		}
	}
	r.refunds = append(r.refunds, refund{payment, "late"})
}

func (r *room) release(number int, player string, t time.Time) error {
	r.settle(t)
	p, err := r.place(number)
	if err != nil {
		return err
	}
	switch {
	case is(p.Player, player) && p.Payment == nil:
		if player == r.Organizer && r.Status == held {
			r.end(cancelled, "cancelled")
			return nil
		}
		p.free()
	case is(p.ReplPlayer, player):
		p.clearRepl()
	default:
		return notHeld
	}
	r.dirty = true
	return nil
}

// leave: before confirmation the place is freed and refunded, and the
// organizer leaving cancels the room. After confirmation the place opens for
// a replacement and the leaver is refunded only if one pays in time.
func (r *room) leave(number int, player string, t time.Time) error {
	r.settle(t)
	p, err := r.place(number)
	if err != nil {
		return err
	}
	if !is(p.Player, player) || p.Payment == nil {
		return cannotLeave
	}
	switch {
	case r.Status == held && player == r.Organizer:
		r.end(cancelled, "cancelled")
		return nil
	case r.Status == held:
		r.refunds = append(r.refunds, refund{*p.Payment, "left"})
		p.free()
	case r.Status == confirmed && !p.Leaving && t.Before(r.replaceDeadline()):
		p.Leaving = true
	default:
		return cannotLeave
	}
	r.dirty = true
	return nil
}

func (r *room) stay(number int, player string, t time.Time) error {
	r.settle(t)
	p, err := r.place(number)
	if err != nil {
		return err
	}
	if !is(p.Player, player) || !p.Leaving {
		return cannotLeave
	}
	// A replacement may be paying right now.
	if p.ReplPlayer != nil {
		return placeTaken
	}
	p.Leaving = false
	r.dirty = true
	return nil
}

func (r *room) paidCount() int {
	n := 0
	for _, p := range r.Places {
		if p.Payment != nil {
			n++
		}
	}
	return n
}

// splitRent gives each place whole tenge; the first places carry the remainder.
func splitRent(rentTenge int64, places int) []int64 {
	base, rest := rentTenge/int64(places), rentTenge%int64(places)
	shares := make([]int64, places)
	for i := range shares {
		shares[i] = base
		if int64(i) < rest {
			shares[i]++
		}
	}
	return shares
}

func earlier(a, b time.Time) time.Time {
	if a.Before(b) {
		return a
	}
	return b
}

func is(p *string, v string) bool { return p != nil && *p == v }
