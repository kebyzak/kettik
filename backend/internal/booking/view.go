package booking

import (
	"context"
	"net/http"
	"time"

	"kettik/internal/web"
)

type playerJSON struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// placeJSON matches the app's Place: a replacement's hold over a leaving
// place is "held" by the replacement, with the leaver in replacing.
type placeJSON struct {
	Number    int         `json:"number"`
	State     string      `json:"state"` // free, held, paid
	Player    *playerJSON `json:"player"`
	Until     *time.Time  `json:"until,omitempty"`
	Leaving   bool        `json:"leaving"`
	Replacing *playerJSON `json:"replacing,omitempty"`
	Share     int64       `json:"share"` // tenge
}

type gameJSON struct {
	ID          string      `json:"id"`
	Venue       venueJSON   `json:"venue"`
	FieldID     string      `json:"fieldId"`
	Start       time.Time   `json:"start"`
	End         time.Time   `json:"end"`
	Rent        int64       `json:"rent"` // tenge
	Teams       int         `json:"teams"`
	Level       string      `json:"level"`
	OrganizerID string      `json:"organizerId"`
	CreatedAt   time.Time   `json:"createdAt"`
	Deadline    time.Time   `json:"deadline"`
	Status      string      `json:"status"` // funding, confirmed, expired, cancelled
	Places      []placeJSON `json:"places"`
}

type venueJSON struct {
	Name    string `json:"name"`
	Address string `json:"address"`
}

func (s *Service) writeGame(w http.ResponseWriter, ctx context.Context, id string, status int) {
	rooms, err := loadRooms(ctx, s.db, "where r.id = $1", id)
	if err != nil {
		s.fail(w, err)
		return
	}
	if len(rooms) == 0 {
		s.reject(w, notFound)
		return
	}
	rooms[0].settle(time.Now())
	games, err := s.toJSON(ctx, rooms)
	if err != nil {
		web.Internal(w, err)
		return
	}
	web.WriteJSON(w, status, games[0])
}

func (s *Service) writeGames(w http.ResponseWriter, ctx context.Context, rooms []*room) {
	games, err := s.toJSON(ctx, rooms)
	if err != nil {
		web.Internal(w, err)
		return
	}
	web.WriteJSON(w, http.StatusOK, games)
}

func (s *Service) toJSON(ctx context.Context, rooms []*room) ([]gameJSON, error) {
	var ids []string
	for _, r := range rooms {
		for _, p := range r.Places {
			for _, id := range []*string{p.Player, p.ReplPlayer} {
				if id != nil {
					ids = append(ids, *id)
				}
			}
		}
	}
	names := map[string]string{}
	rows, err := s.db.Query(ctx, `select id::text, coalesce(name, '') from players where id = any($1::uuid[])`, ids)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id, name string
		if err := rows.Scan(&id, &name); err != nil {
			return nil, err
		}
		names[id] = name
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	player := func(id *string) *playerJSON {
		if id == nil {
			return nil
		}
		return &playerJSON{*id, names[*id]}
	}

	games := make([]gameJSON, 0, len(rooms))
	for _, r := range rooms {
		g := gameJSON{
			ID: r.ID, Venue: venueJSON{r.VenueName, r.VenueAddress}, FieldID: r.FieldID,
			Start: r.Start, End: r.End, Rent: r.Rent / 100, Teams: r.Teams, Level: r.Level,
			OrganizerID: r.Organizer, CreatedAt: r.CreatedAt, Deadline: r.Deadline,
			Status: r.Status, Places: []placeJSON{},
		}
		if r.Status == held {
			g.Status = "funding"
		}
		for _, p := range r.Places {
			pj := placeJSON{Number: p.Number, State: "free", Share: p.Share / 100}
			switch {
			case p.ReplPlayer != nil:
				pj.State, pj.Player, pj.Until, pj.Replacing = "held", player(p.ReplPlayer), p.ReplUntil, player(p.Player)
			case p.Payment != nil:
				pj.State, pj.Player, pj.Leaving = "paid", player(p.Player), p.Leaving
			case p.Player != nil:
				pj.State, pj.Player, pj.Until = "held", player(p.Player), p.Until
			}
			g.Places = append(g.Places, pj)
		}
		games = append(games, g)
	}
	return games, nil
}
