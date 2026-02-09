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
  const status = url.searchParams.get('status') || 'failed'

  let response: Response
  try {
    response = await fetch(buildUrl(`/admin/email-jobs?status=${encodeURIComponent(status)}`), {
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
