# kettik backend

Go, Postgres + PostGIS. Migrations run on API start. Booking rules: `docs/booking-mvp.md`.

```sh
docker compose up -d
DEV=1 AUTH_SECRET=dev-secret-at-least-32-characters-long go run ./cmd/api
go run ./cmd/worker                                    # second terminal
```

`DEV=1` adds `POST /dev/payments/{id}/succeed`, a fake provider until Halyk ePay is wired.
With `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD` and `SMTP_FROM` (optional `SMTP_PORT`, default 587, STARTTLS) the sign-in code is mailed; without them it is printed to the API log.

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
| `GET /venues` | venues with their open fields |
| `GET /fields/{id}/slots?date=YYYY-MM-DD&minutes=60\|90\|120` | free starts that day `{start, end, rent}` |
| `GET /games` | feed: collecting, or confirmed and seeking a replacement |
| `GET /games/{id}` | one game |
| `GET /me/games` | the player's games, past included |
| `POST /games {fieldId, start, end, size, teams, level}` | create; the organizer holds place 1 |
| `POST /games/{id}/places/{n}/hold` | hold a free place, or a leaving one after confirmation |
| `DELETE /games/{id}/places/{n}/hold` | release an unpaid hold |
| `POST /games/{id}/places/{n}/pay` | the payment attempt for the hold `{id, amount, status}` |
| `POST /games/{id}/places/{n}/leave` | leave a paid place |
| `POST /games/{id}/places/{n}/stay` | take back a leave after confirmation |

Venues, fields and tariffs come from kettik business (`business-web/`); a field opens only in its tariffs' hours, Astana time.

A game's `status` is `funding`, `confirmed`, `expired` or `cancelled`. A place's `state` is `free`, `held` or `paid`; a replacement's hold shows the leaver in `replacing`. Money in the API is whole tenge, except payment `amount` in tiyn.

## Business

A business and its owner are added by hand (owner is the only role); the owner then signs in to the cabinet with the usual email code:

```sql
with b as (insert into businesses (name) values ('NIS Mangilik Arena') returning id),
     p as (insert into players (email) values ('owner@example.com')
           on conflict (email) do update set email = excluded.email returning id)
insert into business_members (business_id, player_id) select b.id, p.id from b, p;
```

| | |
|---|---|
| `GET /biz/me` | the owner's businesses `{id, name}` |
| `GET /biz/venues` | their venues with fields and tariffs |
| `POST /biz/venues {businessId, name, address}`, `PUT /biz/venues/{id} {name, address}` | add, edit a venue |
| `POST /biz/venues/{id}/fields {name}`, `PUT /biz/fields/{id} {name}` | add, rename a field |
| `PUT /biz/fields/{id}/tariffs {tariffs: [{days, from, to, price}]}` | replace the tariffs: ISO weekdays, minutes from midnight on half hours, tenge per hour |
| `GET /biz/venues/{id}/day?date=YYYY-MM-DD` | live bookings that day; a kettik game carries `game` |
| `POST /biz/bookings {fieldId, start, end, kind: manual\|block, note}` | an offline booking or a closed interval |
| `DELETE /biz/bookings/{id}` | free it; a game is cancelled and refunded |

## Errors

`{"error": "<reason>"}`:
- sign-in: `bad_email`, `bad_name`, `wrong_code` (with `attemptsLeft`), `code_burned`, `code_expired`, `too_many`, `unauthorized`
- business (400): `bad_text`, `bad_tariffs`, `bad_booking`
- games (409 unless noted): `place_taken`, `already_in_game`, `funding_closed`, `hold_expired`, `not_held`, `cannot_leave`, `too_late`, `slot_taken`, `closed`, `not_found` (404), `no_name` (403), `bad_game` (400)
