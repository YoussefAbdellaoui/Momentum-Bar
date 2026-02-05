import { NextResponse } from 'next/server'
import { createSessionCookie } from '@/lib/adminAuth'

export async function POST(request: Request) {
  const body = await request.json().catch(() => null)
  const password = body?.password

  if (!password || password !== process.env.ADMIN_DASHBOARD_PASSWORD) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  if (!process.env.ADMIN_DASHBOARD_TOKEN_SECRET) {
    return NextResponse.json({ error: 'Server not configured' }, { status: 500 })
  }

  const session = createSessionCookie()
  const response = NextResponse.json({ success: true })
  response.cookies.set(session.name, session.value, session.options)
  return response
}
