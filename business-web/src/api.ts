// The kettik API, same origin. Shapes match backend/README.md.

export type Business = { id: string; name: string }
export type Tariff = { days: number[]; from: number; to: number; price: number }
export type Field = { id: string; name: string; tariffs: Tariff[] }
export type Venue = { id: string; businessId: string; name: string; address: string; fields: Field[] }
export type Booking = {
  id: string
  fieldId: string
  start: string
  end: string
  status: 'held' | 'confirmed'
  kind: 'game' | 'manual' | 'block'
  note: string
  game?: { organizer: string; paid: number; size: number; rent: number; deadline: string; createdAt: string }
}

export class ApiError extends Error {
  constructor(public reason: string) {
    super(reason)
  }
}

const tokenKey = 'kettik.token'

export const token = {
  get: () => localStorage.getItem(tokenKey),
  set: (t: string | null) => (t ? localStorage.setItem(tokenKey, t) : localStorage.removeItem(tokenKey)),
}

/** Fired when the session is gone: the app shows sign-in again. */
export const signedOut = 'kettik:signed-out'

export async function api<T = void>(method: string, path: string, body?: unknown): Promise<T> {
  const headers: Record<string, string> = {}
  const t = token.get()
  if (t) headers.Authorization = `Bearer ${t}`
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  let res: Response
  try {
    res = await fetch(path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) })
  } catch {
    throw new ApiError('offline')
  }
  const text = await res.text()
  const data = text ? JSON.parse(text) : undefined
  if (!res.ok) {
    if (res.status === 401) {
      token.set(null)
      window.dispatchEvent(new Event(signedOut))
    }
    throw new ApiError(data?.error ?? 'internal')
  }
  return data as T
}

const reasons: Record<string, string> = {
  offline: 'Нет связи с сервером',
  bad_email: 'Проверьте email',
  wrong_code: 'Неверный код',
  code_burned: 'Код больше не действует, запросите новый',
  code_expired: 'Код истёк, запросите новый',
  too_many: 'Слишком много попыток, попробуйте через час',
  unauthorized: 'Войдите заново',
  bad_text: 'Заполните название и адрес',
  bad_tariffs: 'Тарифы пересекаются или заполнены неверно',
  bad_booking: 'Проверьте время брони',
  slot_taken: 'Это время уже занято',
  not_found: 'Не найдено',
  internal: 'Ошибка сервера, попробуйте ещё раз',
}

export const say = (e: unknown) => (e instanceof ApiError ? reasons[e.reason] ?? e.reason : 'Что-то пошло не так')
