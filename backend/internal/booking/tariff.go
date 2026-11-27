package booking

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

// Local is the venues' clock: tariffs and calendar days are in Astana time.
// shortcut: one fixed zone for every venue; keep a zone per venue when kettik leaves Kazakhstan.
var Local = time.FixedZone("Astana", 5*60*60)

// Step is the grid of the calendar: bookings start and end on half hours.
const Step = 30 * time.Minute

// Tariff prices a field in [From, To) minutes from local midnight on Days (1 = Monday).
type Tariff struct {
	Days  []int32 `json:"days"`
	From  int     `json:"from"`
	To    int     `json:"to"`
	Price int64   `json:"price"` // tenge per hour
}

// ValidTariffs allows half-hour bounds within one day and no half hour priced twice.
func ValidTariffs(ts []Tariff) bool {
	if len(ts) > 50 {
		return false
	}
	var used [8][48]bool
	for _, t := range ts {
		if len(t.Days) == 0 || t.From < 0 || t.To > 24*60 || t.From >= t.To ||
			t.From%30 != 0 || t.To%30 != 0 || t.Price <= 0 || t.Price > 10_000_000 {
			return false
		}
		for _, d := range t.Days {
			if d < 1 || d > 7 {
				return false
			}
			for m := t.From; m < t.To; m += 30 {
				if used[d][m/30] {
					return false
				}
				used[d][m/30] = true
			}
		}
	}
	return true
}

// OnGrid says t starts a half hour on the local clock.
func OnGrid(t time.Time) bool {
	l := t.In(Local)
	return l.Minute()%30 == 0 && l.Second() == 0 && l.Nanosecond() == 0
}

// rent prices [start, end) half hour by half hour, in whole tenge. ok is false
// when some half hour has no tariff: the field is closed then.
func rent(ts []Tariff, start, end time.Time) (tenge int64, ok bool) {
	var sum int64 // tenge·minutes
	for t := start; t.Before(end); t = t.Add(Step) {
		l := t.In(Local)
		day := int32(l.Weekday())
		if day == 0 {
			day = 7
		}
		m := l.Hour()*60 + l.Minute()
		price := int64(0)
		for _, tf := range ts {
			if tf.From <= m && m < tf.To && has(tf.Days, day) {
				price = tf.Price
				break
			}
		}
		if price == 0 {
			return 0, false
		}
		sum += price * 30
	}
	return sum / 60, true
}

func has(days []int32, d int32) bool {
	for _, x := range days {
		if x == d {
			return true
		}
	}
	return false
}

func LoadTariffs(ctx context.Context, q querier, fieldID string) ([]Tariff, error) {
	rows, err := q.Query(ctx, `
		select days, from_min, to_min, price_per_hour from tariffs
		where field_id = $1 order by from_min`, fieldID)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, pgx.RowToStructByPos[Tariff])
}
