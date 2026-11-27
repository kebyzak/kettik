// Venues run on Astana time (UTC+5), like the backend, whatever the browser's zone.
// A date is 'YYYY-MM-DD'; a time of day is minutes from that date's midnight.

const zone = '+05:00'
const offsetMs = 5 * 60 * 60 * 1000

export const pad = (n: number) => String(n).padStart(2, '0')

export function dateOf(d: Date): string {
  const a = new Date(d.getTime() + offsetMs)
  return `${a.getUTCFullYear()}-${pad(a.getUTCMonth() + 1)}-${pad(a.getUTCDate())}`
}

export const today = () => dateOf(new Date())

export function addDays(date: string, n: number): string {
  const d = new Date(`${date}T00:00:00Z`)
  d.setUTCDate(d.getUTCDate() + n)
  return d.toISOString().slice(0, 10)
}

const midnight = (date: string) => Date.parse(`${date}T00:00:00${zone}`)

/** Minutes from the date's midnight to the instant; may fall outside 0..1440. */
export const minutesOn = (date: string, iso: string) => (Date.parse(iso) - midnight(date)) / 60000

/** The instant at a time of day, as RFC 3339 for the API. */
export const at = (date: string, min: number) => new Date(midnight(date) + min * 60000).toISOString()

/** 1440 reads 24:00, the end of the day. Seconds are dropped. */
export function hm(min: number): string {
  const m = Math.floor(min)
  return `${pad(Math.floor(m / 60))}:${pad(m % 60)}`
}

/** ISO weekday, 1 = Monday. */
export function weekday(date: string): number {
  const d = new Date(`${date}T00:00:00Z`).getUTCDay()
  return d === 0 ? 7 : d
}

export function longDate(date: string): string {
  const s = new Date(`${date}T12:00:00Z`).toLocaleDateString('ru-RU', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    timeZone: 'UTC',
  })
  return s.charAt(0).toUpperCase() + s.slice(1)
}

/** The local date and time of an instant, like 25.11, 09:14. */
export function stamp(iso: string): string {
  const date = dateOf(new Date(iso))
  return `${date.slice(8, 10)}.${date.slice(5, 7)}, ${hm(minutesOn(date, iso))}`
}

export const tenge = (n: number) => `${n.toLocaleString('ru-RU')} ₸`

/** Every half hour from 00:00 to 24:00. */
export const halfHours = Array.from({ length: 49 }, (_, i) => i * 30)

export const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
