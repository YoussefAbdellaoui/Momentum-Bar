import { NextResponse } from 'next/server'
import { requireAdminSession } from '@/lib/adminAuth'

const parseJsonResponse = async (response: Response) => {
  const text = await response.text()
  if (!text) return { data: null, rawText: '' }
  try {
    return { data: JSON.parse(text), rawText: text }
  } catch {
    return { data: null, rawText: text }
  }
}

const getAdminApiUrl = () => {
  return process.env.ADMIN_API_URL || process.env.NEXT_PUBLIC_API_URL || ''
}

const getAdminKey = () => process.env.ADMIN_API_KEY || ''

const buildUrl = (path: string) => {
  const base = getAdminApiUrl().replace(/\/$/, '')
  return `${base}${path}`
}

export async function GET(request: Request) {
  const authResponse = await requireAdminSession()
  if (authResponse) return authResponse

  const baseUrl = getAdminApiUrl()
  const adminKey = getAdminKey()
  if (!baseUrl || !adminKey) {
    return NextResponse.json({ error: 'Server not configured' }, { status: 500 })
  }

  const url = new URL(request.url)
  const limit = url.searchParams.get('limit')

  let response: Response
  try {
    response = await fetch(buildUrl(`/admin/announcements${limit ? `?limit=${limit}` : ''}`), {
      headers: {
        'x-admin-key': adminKey,
      },
      cache: 'no-store',
    })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to reach admin API', detail: String(error) }, { status: 502 })
  }

  const { data, rawText } = await parseJsonResponse(response)
  if (!data && rawText) {
    return NextResponse.json({ error: 'Admin API returned non-JSON', body: rawText }, { status: 502 })
  }
  return NextResponse.json(data ?? {}, { status: response.status })
}

export async function POST(request: Request) {
  const authResponse = await requireAdminSession()
  if (authResponse) return authResponse

  const baseUrl = getAdminApiUrl()
  const adminKey = getAdminKey()
  if (!baseUrl || !adminKey) {
    return NextResponse.json({ error: 'Server not configured' }, { status: 500 })
  }

  const payload = await request.json().catch(() => null)

  let response: Response
  try {
    response = await fetch(buildUrl('/admin/announcements'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-admin-key': adminKey,
      },
      body: JSON.stringify(payload || {}),
    })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to reach admin API', detail: String(error) }, { status: 502 })
  }

  const { data, rawText } = await parseJsonResponse(response)
  if (!data && rawText) {
    return NextResponse.json({ error: 'Admin API returned non-JSON', body: rawText }, { status: 502 })
  }
  return NextResponse.json(data ?? {}, { status: response.status })
}

export async function PATCH(request: Request) {
  const authResponse = await requireAdminSession()
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

  let response: Response
  try {
    response = await fetch(buildUrl(`/admin/announcements/${id}`), {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'x-admin-key': adminKey,
      },
      body: JSON.stringify(payload || {}),
    })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to reach admin API', detail: String(error) }, { status: 502 })
  }

  const { data, rawText } = await parseJsonResponse(response)
  if (!data && rawText) {
    return NextResponse.json({ error: 'Admin API returned non-JSON', body: rawText }, { status: 502 })
  }
  return NextResponse.json(data ?? {}, { status: response.status })
}

export async function DELETE(request: Request) {
  const authResponse = await requireAdminSession()
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

  let response: Response
  try {
    response = await fetch(buildUrl(`/admin/announcements/${id}`), {
      method: 'DELETE',
      headers: {
        'x-admin-key': adminKey,
      },
    })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to reach admin API', detail: String(error) }, { status: 502 })
  }

  const { data, rawText } = await parseJsonResponse(response)
  if (!data && rawText) {
    return NextResponse.json({ error: 'Admin API returned non-JSON', body: rawText }, { status: 502 })
  }
  return NextResponse.json(data ?? {}, { status: response.status })
}
