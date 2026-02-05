import crypto from 'crypto'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

const COOKIE_NAME = 'admin_session'
const SESSION_MAX_AGE_SECONDS = 12 * 60 * 60

const getSecret = () => process.env.ADMIN_DASHBOARD_TOKEN_SECRET || ''

const sign = (payload: string) => {
  const secret = getSecret()
  return crypto.createHmac('sha256', secret).update(payload).digest('base64url')
}

export const createSessionCookie = () => {
  const timestamp = Math.floor(Date.now() / 1000)
  const signature = sign(String(timestamp))
  const value = `${timestamp}.${signature}`

  return {
    name: COOKIE_NAME,
    value,
    options: {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict' as const,
      path: '/',
      maxAge: SESSION_MAX_AGE_SECONDS,
    },
  }
}

export const isSessionValid = async () => {
  const secret = getSecret()
  if (!secret) return false
  const cookieStore = await cookies()
  const cookie = cookieStore.get(COOKIE_NAME)
  if (!cookie?.value) return false

  const [timestampRaw, signature] = cookie.value.split('.')
  if (!timestampRaw || !signature) return false

  const timestamp = Number(timestampRaw)
  if (!Number.isFinite(timestamp)) return false

  const expectedSignature = sign(timestampRaw)
  if (signature !== expectedSignature) return false

  const now = Math.floor(Date.now() / 1000)
  if (now - timestamp > SESSION_MAX_AGE_SECONDS) return false

  return true
}

export const requireAdminSession = async () => {
  if (!(await isSessionValid())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }
  return null
}
