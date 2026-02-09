'use client'

import { useCallback, useEffect, useMemo, useState } from 'react'

interface EmailJob {
  id: number
  email: string
  license_key: string
  tier: string
  status: string
  attempts: number
  max_attempts: number
  next_attempt_at?: string | null
  last_error?: string | null
  created_at?: string | null
  updated_at?: string | null
}

export default function AdminEmailJobsPage() {
  const [password, setPassword] = useState('')
  const [loggedIn, setLoggedIn] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [jobs, setJobs] = useState<EmailJob[]>([])
  const [statusFilter, setStatusFilter] = useState('failed')

  const readErrorMessage = async (res: Response, fallback: string) => {
    try {
      const data = await res.json()
      if (data?.error) return data.error
      if (data?.message) return data.message
      if (typeof data === 'string') return data
    } catch {
      // ignore JSON parse errors
    }
    try {
      const text = await res.text()
      if (text) return text
    } catch {
      // ignore body read errors
    }
    return fallback
  }

  const fetchJobs = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch(`/api/admin/email-jobs?status=${statusFilter}`, { cache: 'no-store' })
      if (res.status === 401) {
        setLoggedIn(false)
        return
      }
      const data = await res.json().catch(() => ({}))
      setJobs(data.jobs || [])
      setLoggedIn(true)
    } catch (err) {
      setError('Failed to load email jobs')
    } finally {
      setLoading(false)
    }
  }, [statusFilter])

  useEffect(() => {
    fetchJobs()
  }, [fetchJobs])

  const handleLogin = async () => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch('/api/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password }),
      })

      if (!res.ok) {
        setError(await readErrorMessage(res, 'Invalid password'))
        return
      }

      setLoggedIn(true)
      setPassword('')
      fetchJobs()
    } catch (err) {
      setError('Login failed')
    } finally {
      setLoading(false)
    }
  }

  const handleRequeue = async (job: EmailJob) => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch('/api/admin/email-jobs/requeue', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: job.id }),
      })

      if (!res.ok) {
        setError(await readErrorMessage(res, 'Failed to requeue email'))
        return
      }

      fetchJobs()
    } catch (err) {
      setError('Failed to requeue email')
    } finally {
      setLoading(false)
    }
  }

  const summary = useMemo(() => {
    const total = jobs.length
    const lastError = jobs[0]?.last_error
    return { total, lastError }
  }, [jobs])

  return (
    <main className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950 text-white">
      <div className="max-w-5xl mx-auto px-6 py-16">
        <div className="flex items-center justify-between mb-10">
          <div>
            <p className="text-sm uppercase tracking-[0.3em] text-white/50">Admin</p>
            <h1 className="text-3xl font-semibold">Email Queue</h1>
          </div>
          {loading && <span className="text-sm text-white/60">Working...</span>}
        </div>

        {!loggedIn ? (
          <div className="max-w-md bg-white/5 border border-white/10 rounded-2xl p-6">
            <h2 className="text-lg font-semibold mb-4">Sign in</h2>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Admin password"
              className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2 text-white"
            />
            {error && <p className="mt-3 text-sm text-red-300">{error}</p>}
            <button
              onClick={handleLogin}
              className="mt-4 w-full rounded-lg bg-white text-slate-900 px-4 py-2 font-semibold"
            >
              Sign in
            </button>
          </div>
        ) : (
          <div className="grid gap-8">
            <section className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <div className="flex flex-wrap items-center gap-4 justify-between">
                <div>
                  <h2 className="text-lg font-semibold">Failed emails</h2>
                  <p className="text-sm text-white/60">
                    Showing {summary.total} jobs · Latest error: {summary.lastError || 'None'}
                  </p>
                </div>

                <div className="flex items-center gap-3">
                  <select
                    value={statusFilter}
                    onChange={(event) => setStatusFilter(event.target.value)}
                    className="rounded-lg bg-black/30 border border-white/10 px-4 py-2 text-white"
                  >
                    <option value="failed">Failed</option>
                    <option value="retry">Retry</option>
                    <option value="pending">Pending</option>
                    <option value="sending">Sending</option>
                    <option value="sent">Sent</option>
                  </select>
                  <button
                    onClick={fetchJobs}
                    className="rounded-lg border border-white/20 px-4 py-2 text-sm"
                  >
                    Refresh
                  </button>
                </div>
              </div>
            </section>

            <section className="bg-white/5 border border-white/10 rounded-2xl p-6">
              {error && <p className="mb-4 text-sm text-red-300">{error}</p>}
              {jobs.length === 0 ? (
                <p className="text-white/60">No email jobs found.</p>
              ) : (
                <div className="grid gap-4">
                  {jobs.map((job) => (
                    <div key={job.id} className="border border-white/10 rounded-xl p-4 bg-black/20">
                      <div className="flex flex-wrap items-center justify-between gap-4">
                        <div>
                          <h3 className="font-semibold">{job.email}</h3>
                          <p className="text-sm text-white/70 mt-1">
                            {job.license_key} · {job.tier} · attempts {job.attempts}/{job.max_attempts}
                          </p>
                          {job.last_error && (
                            <p className="text-xs text-red-300 mt-2">Error: {job.last_error}</p>
                          )}
                        </div>
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleRequeue(job)}
                            className="rounded-lg border border-white/20 px-3 py-1 text-sm"
                          >
                            Re-queue
                          </button>
                        </div>
                      </div>
                      <div className="text-xs text-white/50 mt-3 grid md:grid-cols-2 gap-2">
                        <span>Status: {job.status}</span>
                        {job.next_attempt_at && <span>Next attempt: {job.next_attempt_at}</span>}
                        {job.updated_at && <span>Updated: {job.updated_at}</span>}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </section>
          </div>
        )}
      </div>
    </main>
  )
}
