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
    response = await fetch(buildUrl('/admin/announcements/bulk'), {
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
