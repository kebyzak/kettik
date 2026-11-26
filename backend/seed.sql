-- Dev venues, the same as the app's demo data. Run once on an empty database:
-- docker compose exec -T db psql -U kettik < seed.sql
with v as (
    insert into venues (name, address) values
        ('Манеж Alem', 'Сығанақ 18'),
        ('NIS Mangilik Arena', 'Түркістан 32/4а'),
        ('Поле Jastar', 'Мәңгілік Ел 37'),
        ('Spartak Indoor', 'Кенесары 40')
    returning id, name
)
insert into fields (venue_id, name, price_per_hour)
select id, 'Поле 1', case name when 'Манеж Alem' then 30400 else 33000 end from v;
