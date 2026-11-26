-- +goose Up
create extension if not exists btree_gist;

create table venues (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    address text not null
);

create table fields (
    id uuid primary key default gen_random_uuid(),
    venue_id uuid not null references venues,
    name text not null,
    -- shortcut: one flat price per field in whole tenge; move to tariffs by day and hour with the business cabinet
    price_per_hour int not null check (price_per_hour > 0)
);

-- Holds the field's time. A manual booking has no room and starts confirmed.
create table bookings (
    id uuid primary key default gen_random_uuid(),
    field_id uuid not null references fields,
    during tstzrange not null check (not isempty(during) and lower_inc(during) and not upper_inc(during)),
    status text not null check (status in ('held', 'confirmed', 'expired', 'cancelled')),
    created_at timestamptz not null default now(),
    -- [19:00, 20:00) and [20:00, 21:00) don't overlap.
    exclude using gist (field_id with =, during with &&) where (status in ('held', 'confirmed'))
);

create table rooms (
    id uuid primary key default gen_random_uuid(),
    booking_id uuid not null unique references bookings,
    organizer_id uuid not null references players,
    rent bigint not null check (rent > 0), -- tiyn
    teams int not null,
    level text not null check (level in ('casual', 'middle', 'strong')),
    created_at timestamptz not null default now(),
    deadline timestamptz not null
);

-- One attempt per reservation of a place (hold_id); retried only after a failure.
create table payments (
    id uuid primary key default gen_random_uuid(),
    room_id uuid not null references rooms,
    number int not null,
    hold_id uuid not null,
    player_id uuid not null references players,
    amount bigint not null, -- tiyn
    status text not null default 'pending' check (status in ('pending', 'succeeded', 'failed')),
    created_at timestamptz not null default now()
);
create index on payments (hold_id);

create table places (
    room_id uuid not null references rooms,
    number int not null,
    share bigint not null, -- tiyn
    -- free: no player; reserved: player and hold, no payment; paid: player and payment.
    player_id uuid references players,
    hold_id uuid,
    until timestamptz,
    payment_id uuid references payments,
    -- paid player leaving after confirmation, open to a replacement
    leaving bool not null default false,
    -- replacement's hold over a leaving place
    repl_player_id uuid references players,
    repl_hold_id uuid,
    repl_until timestamptz,
    primary key (room_id, number)
);
create index on places (player_id);
create index on places (repl_player_id);

-- At most one full refund per charge.
create table refunds (
    payment_id uuid primary key references payments,
    reason text not null check (reason in ('expired', 'cancelled', 'left', 'replaced', 'late')),
    status text not null default 'pending' check (status in ('pending', 'done', 'review')),
    created_at timestamptz not null default now()
);

-- +goose Down
drop table refunds;
drop table places;
drop table payments;
drop table rooms;
drop table bookings;
drop table fields;
drop table venues;
