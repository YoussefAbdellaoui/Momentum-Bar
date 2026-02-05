import { NextResponse } from 'next/server'
import { requireAdminSession } from '@/lib/adminAuth'

const getAdminApiUrl = () => {
  return process.env.ADMIN_API_URL || process.env.NEXT_PUBLIC_API_URL || ''
}

const getAdminKey = () => process.env.ADMIN_API_KEY || ''

const buildUrl = (path: string) => {
  const base = getAdminApiUrl().replace(/\/$/, '')
  return `${base}${path}`
}

export async function GET(request: Request) {
  const authResponse = requireAdminSession()
  if (authResponse) return authResponse

  const baseUrl = getAdminApiUrl()
  const adminKey = getAdminKey()
  if (!baseUrl || !adminKey) {
    return NextResponse.json({ error: 'Server not configured' }, { status: 500 })
  }

  const url = new URL(request.url)
  const limit = url.searchParams.get('limit')

  const response = await fetch(buildUrl(`/admin/announcements${limit ? `?limit=${limit}` : ''}`), {
    headers: {
      'x-admin-key': adminKey,
    },
    cache: 'no-store',
  })

  const data = await response.json()
  return NextResponse.json(data, { status: response.status })
}

export async function POST(request: Request) {
  const authResponse = requireAdminSession()
  if (authResponse) return authResponse

  const baseUrl = getAdminApiUrl()
  const adminKey = getAdminKey()
  if (!baseUrl || !adminKey) {
    return NextResponse.json({ error: 'Server not configured' }, { status: 500 })
  }

  const payload = await request.json().catch(() => null)

  const response = await fetch(buildUrl('/admin/announcements'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-admin-key': adminKey,
    },
    body: JSON.stringify(payload || {}),
  })

  const data = await response.json()
  return NextResponse.json(data, { status: response.status })
}

export async function PATCH(request: Request) {
  const authResponse = requireAdminSession()
  if (authResponse) return authResponse

  const baseUrl = getAdminApiUrl()
  const adminKey = getAdminKey()
  if (!baseUrl || !adminKey) {
    return NextResponse.json({ error: 'Server not configured' }, { status: 500 })
  }

  const payload = await request.json().catch(() => null)
  const id = payload?.id
  if (!id) {
    return NextResponse.json({ error: 'Missing announcement id' }, { status: 400 })
  }

  const response = await fetch(buildUrl(`/admin/announcements/${id}`), {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'x-admin-key': adminKey,
    },
    body: JSON.stringify(payload || {}),
  })

  const data = await response.json()
  return NextResponse.json(data, { status: response.status })
}

export async function DELETE(request: Request) {
  const authResponse = requireAdminSession()
  if (authResponse) return authResponse

  const baseUrl = getAdminApiUrl()
  const adminKey = getAdminKey()
  if (!baseUrl || !adminKey) {
    return NextResponse.json({ error: 'Server not configured' }, { status: 500 })
  }

  const url = new URL(request.url)
  const id = url.searchParams.get('id')
  if (!id) {
    return NextResponse.json({ error: 'Missing announcement id' }, { status: 400 })
  }

  const response = await fetch(buildUrl(`/admin/announcements/${id}`), {
    method: 'DELETE',
    headers: {
      'x-admin-key': adminKey,
    },
  })

  const data = await response.json().catch(() => ({}))
  return NextResponse.json(data, { status: response.status })
}
