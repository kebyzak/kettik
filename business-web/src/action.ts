import { useState } from 'react'
import { say } from './api'

/** Runs one request at a time and keeps its error for the form to show. */
export function useAction() {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [done, setDone] = useState(false)
  const run = async (f: () => Promise<unknown>) => {
    setBusy(true)
    setError('')
    setDone(false)
    try {
      await f()
      setDone(true)
    } catch (e) {
      setError(say(e))
    } finally {
      setBusy(false)
    }
  }
  return { busy, error, done, run }
}
