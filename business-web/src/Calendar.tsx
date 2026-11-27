import { useCallback, useEffect, useState } from 'react'
import { api, say, type Booking, type Venue } from './api'
import { useAction } from './action'
import { addDays, at, halfHours, hm, longDate, minutesOn, stamp, tenge, today, weekday } from './time'

const hourPx = 64

type Selection = { kind: 'booking'; id: string } | { kind: 'new' } | null

/** One day of a venue: every field's bookings, kettik's and offline ones together. */
export function Calendar({ venue }: { venue: Venue }) {
  const [date, setDate] = useState(today)
  const [bookings, setBookings] = useState<Booking[] | null>(null)
  const [error, setError] = useState('')
  const [selected, setSelected] = useState<Selection>(null)

  const load = useCallback(async () => {
    try {
      const res = await api<{ bookings: Booking[] }>('GET', `/biz/venues/${venue.id}/day?date=${date}`)
      setBookings(res.bookings)
      setError('')
    } catch (e) {
      setError(say(e))
    }
  }, [venue.id, date])

  useEffect(() => {
    setBookings(null)
    void load()
    // Players book from the app meanwhile.
    const poll = setInterval(() => void load(), 30_000)
    return () => clearInterval(poll)
  }, [load])

  // The day spans the fields' tariff hours, widened to show any booking outside them.
  const day = weekday(date)
  const open = venue.fields.flatMap((f) => f.tariffs.filter((t) => t.days.includes(day)))
  let from = open.length ? Math.min(...open.map((t) => t.from)) : 8 * 60
  let to = open.length ? Math.max(...open.map((t) => t.to)) : 24 * 60
  for (const b of bookings ?? []) {
    from = Math.min(from, Math.max(0, minutesOn(date, b.start)))
    to = Math.max(to, Math.min(24 * 60, minutesOn(date, b.end)))
  }
  from = Math.floor(from / 60) * 60
  to = Math.ceil(to / 60) * 60
  const height = ((to - from) / 60) * hourPx
  const hours = Array.from({ length: (to - from) / 60 }, (_, i) => from + i * 60)

  const chosen = selected?.kind === 'booking' ? bookings?.find((b) => b.id === selected.id) : undefined

  return (
    <div className="calendar">
      <main className="stack grow">
        <div className="row">
          <h1>{longDate(date)}</h1>
          <button className="round" aria-label="Предыдущий день" onClick={() => setDate(addDays(date, -1))}>‹</button>
          <button className="round" aria-label="Следующий день" onClick={() => setDate(addDays(date, 1))}>›</button>
          {date !== today() && <button className="quiet" onClick={() => setDate(today())}>Сегодня</button>}
          <span className="grow" />
          <span className="legend">
            <span><i className="k-confirmed" />Подтверждено</span>
            <span><i className="k-held" />Идёт набор</span>
            <span><i className="k-block" />Закрыто</span>
          </span>
          <button className="primary" onClick={() => setSelected({ kind: 'new' })}>+ Ручная бронь</button>
        </div>
        {error && <p className="error" role="alert">{error}</p>}
        {venue.fields.length === 0 ? (
          <p className="card muted">Добавьте поля в разделе «Поля и тарифы».</p>
        ) : (
          <div className="grid card" style={{ gridTemplateColumns: `56px repeat(${venue.fields.length}, minmax(160px, 1fr))` }}>
            <div className="head" />
            {venue.fields.map((f) => <div key={f.id} className="head">{f.name}</div>)}
            <div className="hours" style={{ height }}>
              {hours.map((h) => <span key={h} style={{ top: ((h - from) / 60) * hourPx }}>{hm(h)}</span>)}
            </div>
            {venue.fields.map((f) => (
              <div key={f.id} className="lane" style={{ height, backgroundSize: `100% ${hourPx}px` }}>
                {(bookings ?? []).filter((b) => b.fieldId === f.id).map((b) => {
                  const s = Math.max(from, minutesOn(date, b.start))
                  const e = Math.min(to, minutesOn(date, b.end))
                  return (
                    <button key={b.id} className={`block ${look(b)}`}
                      aria-pressed={chosen?.id === b.id}
                      style={{ top: ((s - from) / 60) * hourPx + 2, height: ((e - s) / 60) * hourPx - 4 }}
                      onClick={() => setSelected({ kind: 'booking', id: b.id })}>
                      <span className="time">{hm(Math.max(0, minutesOn(date, b.start)))}–{hm(Math.min(24 * 60, minutesOn(date, b.end)))}</span>
                      <span className="title">{title(b)}</span>
                    </button>
                  )
                })}
              </div>
            ))}
          </div>
        )}
      </main>
      <aside className="card stack side" aria-label="Подробности">
        {selected?.kind === 'new' ? (
          <NewBooking venue={venue} date={date} onDone={() => { setSelected(null); void load() }} />
        ) : chosen ? (
          <Details booking={chosen} venue={venue} onDone={() => { setSelected(null); void load() }} />
        ) : (
          <p className="muted">Выберите бронь в календаре или создайте ручную бронь для клиента без kettik.</p>
        )}
      </aside>
    </div>
  )
}

function look(b: Booking): string {
  if (b.kind === 'block') return 'k-block'
  return b.status === 'held' ? 'k-held' : 'k-confirmed'
}

function title(b: Booking): string {
  if (b.kind === 'block') return b.note || 'Закрыто'
  if (b.kind === 'manual') return b.note || 'Ручная бронь'
  const g = b.game!
  return b.status === 'held' ? `Набор ${g.paid}/${g.size} · kettik` : `Состав ${g.paid}/${g.size} · kettik`
}

function Details({ booking: b, venue, onDone }: { booking: Booking; venue: Venue; onDone: () => void }) {
  const { busy, error, run } = useAction()
  const field = venue.fields.find((f) => f.id === b.fieldId)
  const g = b.game
  const cancel = () => {
    const question = g
      ? 'Отменить игру? Всем оплатившим игрокам вернутся деньги.'
      : b.kind === 'block' ? 'Открыть это время для броней?' : 'Снять эту бронь?'
    if (window.confirm(question)) void run(async () => {
      await api('DELETE', `/biz/bookings/${b.id}`)
      onDone()
    })
  }
  return (
    <>
      <div>
        {g && b.status === 'held' && <p className="signal">Идёт набор · держится до {stamp(g.deadline)}</p>}
        <h2>{field?.name} · {stamp(b.start)}–{stamp(b.end).slice(-5)}</h2>
        <p className="muted">
          {g ? `Игра kettik · собирает ${g.organizer || 'игрок'}` : b.kind === 'block' ? 'Время закрыто' : 'Ручная бронь'}
        </p>
      </div>
      {g ? (
        <dl>
          <dt>Оплатили</dt><dd>{g.paid} из {g.size}</dd>
          <dt>Аренда по тарифу</dt><dd>{tenge(g.rent)}</dd>
          <dt>Создана</dt><dd>{stamp(g.createdAt)}</dd>
        </dl>
      ) : (
        b.note && <p>{b.note}</p>
      )}
      {g && b.status === 'held' && (
        <p className="note">Не наберут к сроку — бронь снимется сама, время вернётся в календарь, игроки получат деньги обратно.</p>
      )}
      <span className="grow" />
      {error && <p className="error" role="alert">{error}</p>}
      <button className="danger" disabled={busy} onClick={cancel}>
        {g ? 'Отменить игру и вернуть деньги' : b.kind === 'block' ? 'Открыть время' : 'Снять бронь'}
      </button>
    </>
  )
}

function NewBooking({ venue, date, onDone }: { venue: Venue; date: string; onDone: () => void }) {
  const [fieldId, setFieldId] = useState(venue.fields[0]?.id ?? '')
  const [kind, setKind] = useState<'manual' | 'block'>('manual')
  const [from, setFrom] = useState(18 * 60)
  const [to, setTo] = useState(19 * 60)
  const [note, setNote] = useState('')
  const { busy, error, run } = useAction()
  return (
    <form className="stack" onSubmit={(e) => {
      e.preventDefault()
      void run(async () => {
        await api('POST', '/biz/bookings', { fieldId, start: at(date, from), end: at(date, to), kind, note })
        onDone()
      })
    }}>
      <h2>Новая бронь · {longDate(date)}</h2>
      <div className="segmented" role="radiogroup" aria-label="Тип">
        <button type="button" role="radio" aria-checked={kind === 'manual'} onClick={() => setKind('manual')}>Клиент без kettik</button>
        <button type="button" role="radio" aria-checked={kind === 'block'} onClick={() => setKind('block')}>Закрыть время</button>
      </div>
      <label>Поле
        <select value={fieldId} onChange={(e) => setFieldId(e.target.value)}>
          {venue.fields.map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}
        </select>
      </label>
      <div className="row">
        <label>С
          <select value={from} onChange={(e) => {
            const m = Number(e.target.value)
            setFrom(m)
            if (to <= m) setTo(m + 60 > 24 * 60 ? 24 * 60 : m + 60)
          }}>
            {halfHours.slice(0, -1).map((m) => <option key={m} value={m}>{hm(m)}</option>)}
          </select>
        </label>
        <label>До
          <select value={to} onChange={(e) => setTo(Number(e.target.value))}>
            {halfHours.filter((m) => m > from).map((m) => <option key={m} value={m}>{hm(m)}</option>)}
          </select>
        </label>
      </div>
      <label>{kind === 'manual' ? 'Кто играет' : 'Причина'}
        <input maxLength={200} placeholder={kind === 'manual' ? 'Команда «Офис», +7 701 …' : 'Обслуживание'}
          value={note} onChange={(e) => setNote(e.target.value)} />
      </label>
      {error && <p className="error" role="alert">{error}</p>}
      <button className="primary" disabled={busy || !fieldId}>{kind === 'manual' ? 'Забронировать' : 'Закрыть время'}</button>
    </form>
  )
}
