import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'MomentumBar - Time Zone & Calendar Manager for macOS',
  description: 'The ultimate menu bar app for managing time zones, calendars, and scheduling across the globe. Perfect for remote teams and international businesses.',
  keywords: 'macOS, menu bar, time zones, calendar, productivity, remote work, scheduling',
  openGraph: {
    title: 'MomentumBar - Master Your Time Zones',
    description: 'The ultimate menu bar app for managing time zones and calendars on macOS.',
    type: 'website',
    locale: 'en_US',
    siteName: 'MomentumBar',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'MomentumBar - Time Zone & Calendar Manager',
    description: 'The ultimate menu bar app for managing time zones and calendars on macOS.',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className={`${inter.className} gradient-background`}>
        {/* Animated background orbs */}
        <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
          <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary-400 rounded-full filter blur-3xl opacity-20 animate-blob" />
          <div className="absolute top-1/3 right-1/4 w-96 h-96 bg-purple-500 rounded-full filter blur-3xl opacity-15 animate-blob animation-delay-2000" />
          <div className="absolute bottom-1/4 left-1/3 w-96 h-96 bg-orange-400 rounded-full filter blur-3xl opacity-15 animate-blob animation-delay-4000" />
        </div>

        {/* Grid pattern overlay */}
        <div className="fixed inset-0 opacity-[0.03] pointer-events-none z-0" style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23fff' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
        }} />

        {/* Content */}
        <div className="relative z-10">
          {children}
        </div>
      </body>
    </html>
  )
}
