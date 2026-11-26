-- +goose Up
create table players (
    id uuid primary key default gen_random_uuid(),
    email text not null unique,
    -- null until the player names themselves after the first code
    name text,
    created_at timestamptz not null default now()
);

-- one live code per email; a new code replaces the old one
create table login_codes (
    email text primary key,
    code_hash bytea not null,
    sent_at timestamptz not null default now(),
    attempts int not null default 0
);

create table sessions (
    token_hash bytea primary key,
    player_id uuid not null references players on delete cascade,
    created_at timestamptz not null default now()
);

-- +goose Down
drop table sessions;
drop table login_codes;
drop table players;
