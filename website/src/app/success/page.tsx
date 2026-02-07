'use client'

import { useEffect, useState } from 'react'
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'

export default function SuccessPage() {
  const searchParams = useSearchParams()
  const paymentId = searchParams.get('payment_id')
  const [loading, setLoading] = useState(true)
  const [paymentData, setPaymentData] = useState<any>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!paymentId) {
      setError('No payment information found')
      setLoading(false)
      return
    }

    // Validate payment with backend
    const validatePayment = async () => {
      try {
        const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3000'
        const response = await fetch(`${backendUrl}/api/v1/license/payment/${paymentId}`)
        const data = await response.json()

        if (data.success) {
          setPaymentData(data.payment)
        } else {
          setError(data.error || 'Payment validation failed')
        }
      } catch (err) {
        console.error('Payment validation error:', err)
        setError('Could not validate payment. Please check your email for your license key.')
      } finally {
        setLoading(false)
      }
    }

    validatePayment()
  }, [paymentId])

  if (loading) {
    return (
      <main className="min-h-screen flex items-center justify-center p-4">
        <div className="glass rounded-3xl p-12 max-w-2xl w-full text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-white mx-auto mb-6"></div>
          <h2 className="text-2xl font-bold text-white mb-2">Validating Payment...</h2>
          <p className="text-white/70">Please wait while we confirm your purchase</p>
        </div>
      </main>
    )
  }

  if (error || !paymentData) {
    return (
      <main className="min-h-screen flex items-center justify-center p-4">
        <div className="glass rounded-3xl p-12 max-w-2xl w-full text-center">
          <div className="w-20 h-20 mx-auto mb-6 bg-orange-500/20 rounded-full flex items-center justify-center">
            <svg className="w-10 h-10 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          
          <h1 className="text-3xl font-bold text-white mb-4">Payment Not Found</h1>
          <p className="text-white/80 text-lg mb-6">
            {error || 'We couldn\'t find this payment. Your license may still be processing.'}
          </p>
          
          <div className="glass rounded-xl p-6 text-left mb-8">
            <h3 className="text-white font-semibold mb-3">What to do next:</h3>
            <ul className="space-y-2 text-white/80">
              <li className="flex items-start">
                <span className="text-green-400 mr-2">✓</span>
                Check your email for your license key (may take a few minutes)
              </li>
              <li className="flex items-start">
                <span className="text-green-400 mr-2">✓</span>
                Check your spam/junk folder
              </li>
              <li className="flex items-start">
                <span className="text-green-400 mr-2">✓</span>
                If you don't receive it within 30 minutes, contact support
              </li>
            </ul>
          </div>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link 
              href="/"
              className="px-6 py-3 bg-white/10 hover:bg-white/20 text-white rounded-lg font-medium transition-all"
            >
              Back to Home
            </Link>
            <a 
              href="mailto:support@momentumbar.app"
              className="px-6 py-3 bg-primary-600 hover:bg-primary-700 text-white rounded-lg font-medium transition-all"
            >
              Contact Support
            </a>
          </div>
        </div>
      </main>
    )
  }

  return (
    <main className="min-h-screen flex items-center justify-center p-4">
      <div className="glass rounded-3xl p-12 max-w-2xl w-full text-center">
        {/* Success Icon */}
        <div className="w-20 h-20 mx-auto mb-6 bg-green-500/20 rounded-full flex items-center justify-center animate-scale-in">
          <svg className="w-10 h-10 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
        </div>
        
        <h1 className="text-4xl font-bold text-white mb-4">Payment Successful! 🎉</h1>
        <p className="text-white/80 text-lg mb-8">
          Thank you for purchasing MomentumBar {paymentData.tier.charAt(0).toUpperCase() + paymentData.tier.slice(1)}!
        </p>

        {/* Payment Details */}
        <div className="glass rounded-xl p-6 mb-8 text-left">
          <div className="grid gap-4">
            <div>
              <p className="text-white/60 text-sm mb-1">Email</p>
              <p className="text-white font-medium">{paymentData.email}</p>
            </div>
            <div>
              <p className="text-white/60 text-sm mb-1">License Tier</p>
              <p className="text-white font-medium capitalize">{paymentData.tier}</p>
            </div>
            <div>
              <p className="text-white/60 text-sm mb-1">Payment ID</p>
              <p className="text-white/60 font-mono text-sm break-all">{paymentData.id}</p>
            </div>
          </div>
        </div>

        {/* Next Steps */}
        <div className="glass rounded-xl p-6 text-left mb-8">
          <h3 className="text-white font-semibold mb-4">What happens next?</h3>
          <ul className="space-y-3 text-white/80">
            <li className="flex items-start">
              <span className="text-green-400 mr-3 mt-1">✓</span>
              <span>Check your email at <strong className="text-white">{paymentData.email}</strong> for your license key</span>
            </li>
            <li className="flex items-start">
              <span className="text-green-400 mr-3 mt-1">✓</span>
              <span>If you don't see it, check your spam/junk folder</span>
            </li>
            <li className="flex items-start">
              <span className="text-green-400 mr-3 mt-1">✓</span>
              <span>Open MomentumBar and navigate to Settings → License</span>
            </li>
            <li className="flex items-start">
              <span className="text-green-400 mr-3 mt-1">✓</span>
              <span>Enter your license key to unlock all premium features</span>
            </li>
          </ul>
        </div>

        {/* Support */}
        <p className="text-white/70 mb-6">
          Having trouble? Contact us at{' '}
          <a href="mailto:support@momentumbar.app" className="text-primary-300 hover:text-primary-200 font-medium">
            support@momentumbar.app
          </a>
        </p>

        {/* CTA */}
        <div className="pt-6 border-t border-white/10">
          <Link 
            href="/"
            className="inline-block px-8 py-3 bg-primary-600 hover:bg-primary-700 text-white rounded-lg font-medium transition-all hover:scale-105"
          >
            Back to Home
          </Link>
        </div>
      </div>
    </main>
  )
}
