import { useCallback, useEffect, useState } from 'react'
import { api, say, signedOut, token, type Business, type Venue } from './api'
import { useAction } from './action'
import { Calendar } from './Calendar'
import { Venues } from './Venues'

export function App() {
  const [signedIn, setSignedIn] = useState(() => token.get() !== null)
  useEffect(() => {
    const out = () => setSignedIn(false)
    window.addEventListener(signedOut, out)
    return () => window.removeEventListener(signedOut, out)
  }, [])
  return signedIn ? <Cabinet /> : <SignIn onDone={() => setSignedIn(true)} />
}

function SignIn({ onDone }: { onDone: () => void }) {
  const [email, setEmail] = useState('')
  const [code, setCode] = useState('')
  const [sent, setSent] = useState(false)
  const { busy, error, run } = useAction()

  const send = () =>
    run(async () => {
      await api('POST', '/auth/code', { email })
      setSent(true)
    })
  const verify = () =>
    run(async () => {
      const res = await api<{ token: string }>('POST', '/auth/verify', { email, code })
      token.set(res.token)
      onDone()
    })

  return (
    <main className="signin">
      <form
        className="card stack"
        onSubmit={(e) => {
          e.preventDefault()
          void (sent ? verify() : send())
        }}
      >
        <Logo />
        <h1>Вход для площадок</h1>
        <label>
          Email
          <input type="email" required autoComplete="email" value={email} disabled={sent}
            onChange={(e) => setEmail(e.target.value)} />
        </label>
        {sent && (
          <label>
            Код из письма
            <input inputMode="numeric" autoComplete="one-time-code" required maxLength={6} value={code} autoFocus
              onChange={(e) => setCode(e.target.value)} />
          </label>
        )}
        {error && <p className="error" role="alert">{error}</p>}
        <button className="primary" disabled={busy}>{sent ? 'Войти' : 'Получить код'}</button>
        {sent && (
          <button type="button" className="quiet" onClick={() => { setSent(false); setCode('') }}>
            Другой email
          </button>
        )}
      </form>
    </main>
  )
}

type Tab = 'calendar' | 'venues'

function Cabinet() {
  const [businesses, setBusinesses] = useState<Business[] | null>(null)
  const [venues, setVenues] = useState<Venue[]>([])
  const [venueId, setVenueId] = useState('')
  const [tab, setTab] = useState<Tab>('calendar')
  const [error, setError] = useState('')

  const reload = useCallback(async () => {
    try {
      const [b, v] = await Promise.all([api<Business[]>('GET', '/biz/me'), api<Venue[]>('GET', '/biz/venues')])
      setBusinesses(b)
      setVenues(v)
      setVenueId((id) => (v.some((x) => x.id === id) ? id : v[0]?.id ?? ''))
      if (v.length === 0) setTab('venues')
      setError('')
    } catch (e) {
      setError(say(e))
    }
  }, [])
  useEffect(() => {
    void reload()
  }, [reload])

  const signOut = async () => {
    await api('POST', '/auth/logout').catch(() => {})
    token.set(null)
    window.dispatchEvent(new Event(signedOut))
  }

  if (businesses === null) {
    return <main className="signin">{error ? <p className="error" role="alert">{error}</p> : <p>Загрузка…</p>}</main>
  }
  if (businesses.length === 0) {
    return (
      <main className="signin">
        <div className="card stack">
          <Logo />
          <h1>Этот email не подключён</h1>
          <p className="muted">Напишите нам, и мы подключим вашу площадку к kettik business.</p>
          <button className="quiet" onClick={signOut}>Выйти</button>
        </div>
      </main>
    )
  }
  const venue = venues.find((v) => v.id === venueId)
  return (
    <>
      <header className="top">
        <Logo />
        <nav aria-label="Разделы" className="tabs">
          <button aria-current={tab === 'calendar' ? 'page' : undefined} disabled={!venue}
            onClick={() => setTab('calendar')}>Календарь</button>
          <button aria-current={tab === 'venues' ? 'page' : undefined} onClick={() => setTab('venues')}>
            Поля и тарифы
          </button>
        </nav>
        <span className="grow" />
        {venues.length > 1 && (
          <label className="venue-pick">
            <span className="sr">Площадка</span>
            <select value={venueId} onChange={(e) => setVenueId(e.target.value)}>
              {venues.map((v) => <option key={v.id} value={v.id}>{v.name}</option>)}
            </select>
          </label>
        )}
        {venues.length === 1 && <span className="pill">{venues[0].name}</span>}
        <button className="quiet" onClick={signOut}>Выйти</button>
      </header>
      {error && <p className="error page" role="alert">{error}</p>}
      {tab === 'calendar' && venue ? (
        <Calendar venue={venue} />
      ) : (
        <Venues business={businesses[0]} venues={venues} reload={reload} />
      )}
    </>
  )
}

function Logo() {
  return (
    <span className="logo">
      kettik<small>business</small>
    </span>
  )
}
