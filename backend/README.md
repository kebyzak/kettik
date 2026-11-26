# kettik backend

Go, Postgres + PostGIS. Migrations run on API start. Booking rules: `docs/booking-mvp.md`.

```sh
docker compose up -d
docker compose exec -T db psql -U kettik < seed.sql   # once: dev venues
DEV=1 AUTH_SECRET=dev-secret-at-least-32-characters-long go run ./cmd/api
go run ./cmd/worker                                    # second terminal
```

`DEV=1` adds `POST /dev/payments/{id}/succeed`, a fake provider until Halyk ePay is wired.
Until an email provider is picked, the sign-in code is printed to the API log.

## Sign-in

```sh
curl -i localhost:8080/auth/code -d '{"email":"me@example.com"}'
curl localhost:8080/auth/verify -d '{"email":"me@example.com","code":"123456"}'
curl localhost:8080/me -H "Authorization: Bearer <token>" -d '{"name":"Арман"}'
```

`GET /me`, `POST /auth/logout`.

## Games

| | |
|---|---|
| `GET /venues` | venues with their fields and hourly price |
| `GET /fields/{id}/busy?from=&to=` | taken intervals (RFC 3339) |
| `GET /games` | feed: collecting, or confirmed and seeking a replacement |
| `GET /games/{id}` | one game |
| `GET /me/games` | the player's games, past included |
| `POST /games {fieldId, start, end, size, teams, level}` | create; the organizer holds place 1 |
| `POST /games/{id}/places/{n}/hold` | hold a free place, or a leaving one after confirmation |
| `DELETE /games/{id}/places/{n}/hold` | release an unpaid hold |
| `POST /games/{id}/places/{n}/pay` | the payment attempt for the hold `{id, amount, status}` |
| `POST /games/{id}/places/{n}/leave` | leave a paid place |
| `POST /games/{id}/places/{n}/stay` | take back a leave after confirmation |

A game's `status` is `funding`, `confirmed`, `expired` or `cancelled`. A place's `state` is `free`, `held` or `paid`; a replacement's hold shows the leaver in `replacing`. Money in the API is whole tenge, except payment `amount` in tiyn.

## Errors

`{"error": "<reason>"}`:
- sign-in: `bad_email`, `bad_name`, `wrong_code` (with `attemptsLeft`), `code_burned`, `code_expired`, `too_many`, `unauthorized`
- games (409 unless noted): `place_taken`, `already_in_game`, `funding_closed`, `hold_expired`, `not_held`, `cannot_leave`, `too_late`, `slot_taken`, `not_found` (404), `no_name` (403), `bad_game` (400)
