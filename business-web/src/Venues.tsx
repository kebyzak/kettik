import { useState } from 'react'
import { api, type Business, type Field, type Tariff, type Venue } from './api'
import { useAction } from './action'
import { dayNames, halfHours, hm } from './time'

type Props = { business: Business; venues: Venue[]; reload: () => Promise<void> }

// shortcut: new venues go to the member's first business; add a picker when one person runs several.
export function Venues({ business, venues, reload }: Props) {
  return (
    <main className="page stack">
      <h1>Поля и тарифы</h1>
      <p className="muted">
        Поле открыто для игроков kettik только в часы своих тарифов. Время по Астане. Цена за час,
        игра делит её между участниками.
      </p>
      {venues.map((v) => <VenueCard key={v.id} venue={v} reload={reload} />)}
      <NewVenue business={business} reload={reload} first={venues.length === 0} />
    </main>
  )
}

function NewVenue({ business, reload, first }: { business: Business; reload: () => Promise<void>; first: boolean }) {
  const [name, setName] = useState('')
  const [address, setAddress] = useState('')
  const { busy, error, run } = useAction()
  return (
    <form className="card stack" onSubmit={(e) => {
      e.preventDefault()
      void run(async () => {
        await api('POST', '/biz/venues', { businessId: business.id, name, address })
        setName('')
        setAddress('')
        await reload()
      })
    }}>
      <h2>{first ? 'Добавьте вашу площадку' : 'Новая площадка'}</h2>
      <div className="row">
        <label>Название<input required maxLength={80} value={name} onChange={(e) => setName(e.target.value)} /></label>
        <label className="grow">Адрес<input required maxLength={200} value={address} onChange={(e) => setAddress(e.target.value)} /></label>
      </div>
      {error && <p className="error" role="alert">{error}</p>}
      <div><button className="primary" disabled={busy}>Добавить площадку</button></div>
    </form>
  )
}

function VenueCard({ venue, reload }: { venue: Venue; reload: () => Promise<void> }) {
  const [name, setName] = useState(venue.name)
  const [address, setAddress] = useState(venue.address)
  const [newField, setNewField] = useState('')
  const save = useAction()
  const add = useAction()
  return (
    <section className="card stack">
      <form className="row end" onSubmit={(e) => {
        e.preventDefault()
        void save.run(async () => {
          await api('PUT', `/biz/venues/${venue.id}`, { name, address })
          await reload()
        })
      }}>
        <label>Площадка<input required maxLength={80} value={name} onChange={(e) => setName(e.target.value)} /></label>
        <label className="grow">Адрес<input required maxLength={200} value={address} onChange={(e) => setAddress(e.target.value)} /></label>
        <button disabled={save.busy}>Сохранить</button>
        <Status action={save} />
      </form>

      {venue.fields.map((f) => <FieldCard key={f.id} field={f} reload={reload} />)}

      <form className="row end" onSubmit={(e) => {
        e.preventDefault()
        void add.run(async () => {
          await api('POST', `/biz/venues/${venue.id}/fields`, { name: newField })
          setNewField('')
          await reload()
        })
      }}>
        <label>Новое поле<input required maxLength={40} placeholder="Поле 2" value={newField}
          onChange={(e) => setNewField(e.target.value)} /></label>
        <button disabled={add.busy}>Добавить поле</button>
        <Status action={add} />
      </form>
    </section>
  )
}

type Row = { days: number[]; from: number; to: number; price: string }

const toRow = (t: Tariff): Row => ({ ...t, price: String(t.price) })

function FieldCard({ field, reload }: { field: Field; reload: () => Promise<void> }) {
  const [name, setName] = useState(field.name)
  const [rows, setRows] = useState<Row[]>(field.tariffs.map(toRow))
  const rename = useAction()
  const save = useAction()
  const change = (i: number, patch: Partial<Row>) => setRows(rows.map((r, j) => (j === i ? { ...r, ...patch } : r)))

  return (
    <div className="field stack">
      <form className="row end" onSubmit={(e) => {
        e.preventDefault()
        void rename.run(async () => {
          await api('PUT', `/biz/fields/${field.id}`, { name })
          await reload()
        })
      }}>
        <label>Поле<input required maxLength={40} value={name} onChange={(e) => setName(e.target.value)} /></label>
        <button disabled={rename.busy}>Переименовать</button>
        <Status action={rename} />
      </form>

      <form className="stack" onSubmit={(e) => {
        e.preventDefault()
        void save.run(async () => {
          const tariffs: Tariff[] = rows.map((r) => ({ days: r.days, from: r.from, to: r.to, price: Number(r.price) }))
          await api('PUT', `/biz/fields/${field.id}/tariffs`, { tariffs })
          await reload()
        })
      }}>
        <h3>Тарифы</h3>
        {rows.length === 0 && <p className="muted">Тарифов нет: поле закрыто для игроков.</p>}
        {rows.map((r, i) => (
          <fieldset key={i} className="tariff">
            <legend className="sr">Тариф {i + 1}</legend>
            <div className="days" role="group" aria-label="Дни недели">
              {dayNames.map((d, k) => {
                const day = k + 1
                const on = r.days.includes(day)
                return (
                  <button type="button" key={d} aria-pressed={on} className={on ? 'on' : ''}
                    onClick={() => change(i, { days: on ? r.days.filter((x) => x !== day) : [...r.days, day].sort() })}>
                    {d}
                  </button>
                )
              })}
            </div>
            <label>С
              <select value={r.from} onChange={(e) => change(i, { from: Number(e.target.value) })}>
                {halfHours.slice(0, -1).map((m) => <option key={m} value={m}>{hm(m)}</option>)}
              </select>
            </label>
            <label>До
              <select value={r.to} onChange={(e) => change(i, { to: Number(e.target.value) })}>
                {halfHours.slice(1).map((m) => <option key={m} value={m}>{hm(m)}</option>)}
              </select>
            </label>
            <label>₸ за час
              <input type="number" required min={1} step={1} value={r.price} className="price"
                onChange={(e) => change(i, { price: e.target.value })} />
            </label>
            <button type="button" className="quiet" aria-label={`Удалить тариф ${i + 1}`}
              onClick={() => setRows(rows.filter((_, j) => j !== i))}>Удалить</button>
          </fieldset>
        ))}
        <div className="row">
          <button type="button" className="quiet"
            onClick={() => setRows([...rows, { days: [1, 2, 3, 4, 5], from: 8 * 60, to: 24 * 60, price: '' }])}>
            + Тариф
          </button>
          <span className="grow" />
          <Status action={save} />
          <button className="primary" disabled={save.busy}>Сохранить тарифы</button>
        </div>
      </form>
    </div>
  )
}

function Status({ action }: { action: { error: string; done: boolean } }) {
  if (action.error) return <span className="error" role="alert">{action.error}</span>
  return action.done ? <span className="ok" role="status">Сохранено</span> : null
}
