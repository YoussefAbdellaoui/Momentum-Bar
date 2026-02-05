'use client'

import { useEffect, useMemo, useState } from 'react'

interface Announcement {
  id: number
  title: string
  body: string
  type: 'info' | 'warning' | 'critical'
  link_url?: string | null
  starts_at?: string | null
  ends_at?: string | null
  min_app_version?: string | null
  max_app_version?: string | null
  is_active?: boolean
  created_at?: string
}

const defaultForm = {
  title: '',
  body: '',
  type: 'info',
  linkUrl: '',
  startsAt: '',
  endsAt: '',
  minAppVersion: '',
  maxAppVersion: '',
  isActive: true,
}

export default function AdminAnnouncementsPage() {
  const [password, setPassword] = useState('')
  const [loggedIn, setLoggedIn] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [announcements, setAnnouncements] = useState<Announcement[]>([])
  const [form, setForm] = useState(defaultForm)

  const isFormValid = useMemo(() => form.title.trim().length > 0 && form.body.trim().length > 0, [form])

  const fetchAnnouncements = async () => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch('/api/admin/announcements', { cache: 'no-store' })
      if (res.status === 401) {
        setLoggedIn(false)
        return
      }
      const data = await res.json()
      setAnnouncements(data.announcements || [])
      setLoggedIn(true)
    } catch (err) {
      setError('Failed to load announcements')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAnnouncements()
  }, [])

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
        setError('Invalid password')
        return
      }

      setLoggedIn(true)
      setPassword('')
      fetchAnnouncements()
    } catch (err) {
      setError('Login failed')
    } finally {
      setLoading(false)
    }
  }

  const handleCreate = async () => {
    if (!isFormValid) return
    setLoading(true)
    setError(null)

    try {
      const payload = {
        title: form.title,
        body: form.body,
        type: form.type,
        linkUrl: form.linkUrl || undefined,
        startsAt: form.startsAt || undefined,
        endsAt: form.endsAt || undefined,
        minAppVersion: form.minAppVersion || undefined,
        maxAppVersion: form.maxAppVersion || undefined,
        isActive: form.isActive,
      }

      const res = await fetch('/api/admin/announcements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })

      if (!res.ok) {
        setError('Failed to create announcement')
        return
      }

      setForm(defaultForm)
      fetchAnnouncements()
    } catch (err) {
      setError('Failed to create announcement')
    } finally {
      setLoading(false)
    }
  }

  const handleToggleActive = async (announcement: Announcement) => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch('/api/admin/announcements', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: announcement.id, isActive: !announcement.is_active }),
      })

      if (!res.ok) {
        setError('Failed to update announcement')
        return
      }

      fetchAnnouncements()
    } catch (err) {
      setError('Failed to update announcement')
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id: number) => {
    if (!confirm('Delete this announcement?')) return
    setLoading(true)
    setError(null)

    try {
      const res = await fetch(`/api/admin/announcements?id=${id}`, {
        method: 'DELETE',
      })

      if (!res.ok) {
        setError('Failed to delete announcement')
        return
      }

      fetchAnnouncements()
    } catch (err) {
      setError('Failed to delete announcement')
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950 text-white">
      <div className="max-w-5xl mx-auto px-6 py-16">
        <div className="flex items-center justify-between mb-10">
          <div>
            <p className="text-sm uppercase tracking-[0.3em] text-white/50">Admin</p>
            <h1 className="text-3xl font-semibold">Announcements</h1>
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
          <div className="grid gap-10">
            <section className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h2 className="text-lg font-semibold mb-4">Create announcement</h2>
              <div className="grid gap-4">
                <div className="grid md:grid-cols-2 gap-4">
                  <input
                    value={form.title}
                    onChange={(event) => setForm({ ...form, title: event.target.value })}
                    placeholder="Title"
                    className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2"
                  />
                  <select
                    value={form.type}
                    onChange={(event) => setForm({ ...form, type: event.target.value })}
                    className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2"
                  >
                    <option value="info">Info</option>
                    <option value="warning">Warning</option>
                    <option value="critical">Critical</option>
                  </select>
                </div>

                <textarea
                  value={form.body}
                  onChange={(event) => setForm({ ...form, body: event.target.value })}
                  placeholder="Message"
                  className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2 min-h-[120px]"
                />

                <div className="grid md:grid-cols-2 gap-4">
                  <input
                    value={form.linkUrl}
                    onChange={(event) => setForm({ ...form, linkUrl: event.target.value })}
                    placeholder="Link URL (optional)"
                    className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2"
                  />
                  <label className="flex items-center gap-3 text-sm text-white/70">
                    <input
                      type="checkbox"
                      checked={form.isActive}
                      onChange={(event) => setForm({ ...form, isActive: event.target.checked })}
                      className="h-4 w-4"
                    />
                    Active
                  </label>
                </div>

                <div className="grid md:grid-cols-2 gap-4">
                  <input
                    value={form.startsAt}
                    onChange={(event) => setForm({ ...form, startsAt: event.target.value })}
                    placeholder="Starts at (YYYY-MM-DD or ISO)"
                    className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2"
                  />
                  <input
                    value={form.endsAt}
                    onChange={(event) => setForm({ ...form, endsAt: event.target.value })}
                    placeholder="Ends at (YYYY-MM-DD or ISO)"
                    className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2"
                  />
                </div>

                <div className="grid md:grid-cols-2 gap-4">
                  <input
                    value={form.minAppVersion}
                    onChange={(event) => setForm({ ...form, minAppVersion: event.target.value })}
                    placeholder="Min app version (optional)"
                    className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2"
                  />
                  <input
                    value={form.maxAppVersion}
                    onChange={(event) => setForm({ ...form, maxAppVersion: event.target.value })}
                    placeholder="Max app version (optional)"
                    className="w-full rounded-lg bg-black/30 border border-white/10 px-4 py-2"
                  />
                </div>
              </div>

              {error && <p className="mt-3 text-sm text-red-300">{error}</p>}

              <button
                onClick={handleCreate}
                disabled={!isFormValid || loading}
                className="mt-4 rounded-lg bg-white text-slate-900 px-4 py-2 font-semibold disabled:opacity-50"
              >
                Create announcement
              </button>
            </section>

            <section className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h2 className="text-lg font-semibold mb-4">Existing announcements</h2>
              <div className="grid gap-4">
                {announcements.length === 0 && (
                  <p className="text-white/60">No announcements yet.</p>
                )}
                {announcements.map((announcement) => (
                  <div
                    key={announcement.id}
                    className="border border-white/10 rounded-xl p-4 bg-black/20"
                  >
                    <div className="flex items-center justify-between gap-4">
                      <div>
                        <h3 className="font-semibold">{announcement.title}</h3>
                        <p className="text-sm text-white/70 mt-1">{announcement.body}</p>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleToggleActive(announcement)}
                          className="rounded-lg border border-white/20 px-3 py-1 text-sm"
                        >
                          {announcement.is_active ? 'Disable' : 'Enable'}
                        </button>
                        <button
                          onClick={() => handleDelete(announcement.id)}
                          className="rounded-lg border border-red-400/40 text-red-300 px-3 py-1 text-sm"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                    <div className="text-xs text-white/50 mt-3 grid md:grid-cols-2 gap-2">
                      <span>Type: {announcement.type}</span>
                      <span>Active: {announcement.is_active ? 'yes' : 'no'}</span>
                      {announcement.link_url && <span>Link: {announcement.link_url}</span>}
                      {announcement.starts_at && <span>Starts: {announcement.starts_at}</span>}
                      {announcement.ends_at && <span>Ends: {announcement.ends_at}</span>}
                      {announcement.min_app_version && (
                        <span>Min version: {announcement.min_app_version}</span>
                      )}
                      {announcement.max_app_version && (
                        <span>Max version: {announcement.max_app_version}</span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </section>
          </div>
        )}
      </div>
    </main>
  )
}
