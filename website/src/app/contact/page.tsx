'use client'

import { useState, useEffect } from 'react'
import { useSearchParams } from 'next/navigation'
import { motion } from 'framer-motion'
import { Send, ArrowLeft, Loader2, CheckCircle, Mail, Building, Users, MessageSquare } from 'lucide-react'
import Link from 'next/link'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'

export default function ContactPage() {
  const searchParams = useSearchParams()
  const plan = searchParams.get('plan')

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    company: '',
    seats: '',
    subject: plan === 'enterprise' ? 'Enterprise Inquiry' : 'General Inquiry',
    message: '',
  })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (plan === 'enterprise') {
      setFormData(prev => ({
        ...prev,
        subject: 'Enterprise Inquiry',
        message: 'Hi, I\'m interested in MomentumBar Enterprise for my team.\n\n',
      }))
    }
  }, [plan])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    setError('')

    try {
      // In production, replace with your actual form submission endpoint
      // For now, we'll use mailto as a fallback
      const mailtoLink = `mailto:contact@whyandkei.com?subject=${encodeURIComponent(formData.subject)}&body=${encodeURIComponent(
        `Name: ${formData.name}\nEmail: ${formData.email}\nCompany: ${formData.company || 'N/A'}\nSeats needed: ${formData.seats || 'N/A'}\n\nMessage:\n${formData.message}`
      )}`

      // Simulate a brief delay for UX
      await new Promise(resolve => setTimeout(resolve, 1000))

      // Open mailto link
      window.location.href = mailtoLink

      setIsSubmitted(true)
    } catch (err) {
      setError('Something went wrong. Please try again or email us directly at contact@whyandkei.com')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value,
    }))
  }

  return (
    <main className="min-h-screen">
      <Navbar />

      <section className="pt-32 pb-24 md:pt-40 md:pb-32">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* Back link */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            className="mb-8"
          >
            <Link
              href="/"
              className="inline-flex items-center text-white/70 hover:text-white transition"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to Home
            </Link>
          </motion.div>

          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center mb-12"
          >
            <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
              {plan === 'enterprise' ? 'Contact Sales' : 'Get in Touch'}
            </h1>
            <p className="text-xl text-white/70 max-w-2xl mx-auto">
              {plan === 'enterprise'
                ? 'Tell us about your team and we\'ll create a custom plan that fits your needs.'
                : 'Have a question or feedback? We\'d love to hear from you.'}
            </p>
          </motion.div>

          {/* Form Card */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white/10 backdrop-blur-xl rounded-3xl p-8 md:p-10 border border-white/20"
          >
            {isSubmitted ? (
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="text-center py-12"
              >
                <div className="w-20 h-20 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-6">
                  <CheckCircle className="w-10 h-10 text-green-400" />
                </div>
                <h2 className="text-2xl font-bold text-white mb-4">Message Sent!</h2>
                <p className="text-white/70 mb-8">
                  Your email client should have opened. If not, please email us directly at{' '}
                  <a href="mailto:contact@whyandkei.com" className="text-primary-300 hover:text-primary-200">
                    contact@whyandkei.com
                  </a>
                </p>
                <Link
                  href="/"
                  className="inline-flex items-center px-6 py-3 bg-white text-primary-700 rounded-xl font-semibold hover:bg-gray-100 transition"
                >
                  Return Home
                </Link>
              </motion.div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid md:grid-cols-2 gap-6">
                  {/* Name */}
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-white/80 mb-2">
                      Your Name *
                    </label>
                    <div className="relative">
                      <input
                        type="text"
                        id="name"
                        name="name"
                        value={formData.name}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/40 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none transition"
                        placeholder="John Doe"
                      />
                    </div>
                  </div>

                  {/* Email */}
                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-white/80 mb-2">
                      Email Address *
                    </label>
                    <div className="relative">
                      <input
                        type="email"
                        id="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        required
                        className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/40 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none transition"
                        placeholder="john@company.com"
                      />
                    </div>
                  </div>
                </div>

                {plan === 'enterprise' && (
                  <div className="grid md:grid-cols-2 gap-6">
                    {/* Company */}
                    <div>
                      <label htmlFor="company" className="block text-sm font-medium text-white/80 mb-2">
                        Company Name
                      </label>
                      <div className="relative">
                        <Building className="absolute left-4 top-3.5 w-5 h-5 text-white/40" />
                        <input
                          type="text"
                          id="company"
                          name="company"
                          value={formData.company}
                          onChange={handleChange}
                          className="w-full pl-12 pr-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/40 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none transition"
                          placeholder="Acme Inc."
                        />
                      </div>
                    </div>

                    {/* Seats */}
                    <div>
                      <label htmlFor="seats" className="block text-sm font-medium text-white/80 mb-2">
                        Number of Seats Needed
                      </label>
                      <div className="relative">
                        <Users className="absolute left-4 top-3.5 w-5 h-5 text-white/40" />
                        <select
                          id="seats"
                          name="seats"
                          value={formData.seats}
                          onChange={handleChange}
                          className="w-full pl-12 pr-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none transition appearance-none cursor-pointer"
                        >
                          <option value="" className="bg-gray-800">Select...</option>
                          <option value="6-10" className="bg-gray-800">6-10 seats</option>
                          <option value="11-25" className="bg-gray-800">11-25 seats</option>
                          <option value="26-50" className="bg-gray-800">26-50 seats</option>
                          <option value="51-100" className="bg-gray-800">51-100 seats</option>
                          <option value="100+" className="bg-gray-800">100+ seats</option>
                        </select>
                      </div>
                    </div>
                  </div>
                )}

                {/* Subject */}
                <div>
                  <label htmlFor="subject" className="block text-sm font-medium text-white/80 mb-2">
                    Subject *
                  </label>
                  <select
                    id="subject"
                    name="subject"
                    value={formData.subject}
                    onChange={handleChange}
                    required
                    className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none transition appearance-none cursor-pointer"
                  >
                    <option value="General Inquiry" className="bg-gray-800">General Inquiry</option>
                    <option value="Enterprise Inquiry" className="bg-gray-800">Enterprise Inquiry</option>
                    <option value="Technical Support" className="bg-gray-800">Technical Support</option>
                    <option value="Feature Request" className="bg-gray-800">Feature Request</option>
                    <option value="Partnership" className="bg-gray-800">Partnership</option>
                    <option value="Other" className="bg-gray-800">Other</option>
                  </select>
                </div>

                {/* Message */}
                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-white/80 mb-2">
                    Message *
                  </label>
                  <div className="relative">
                    <MessageSquare className="absolute left-4 top-3.5 w-5 h-5 text-white/40" />
                    <textarea
                      id="message"
                      name="message"
                      value={formData.message}
                      onChange={handleChange}
                      required
                      rows={5}
                      className="w-full pl-12 pr-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/40 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none transition resize-none"
                      placeholder="Tell us how we can help..."
                    />
                  </div>
                </div>

                {error && (
                  <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="bg-red-500/20 text-red-200 p-4 rounded-xl text-sm"
                  >
                    {error}
                  </motion.div>
                )}

                {/* Submit */}
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full bg-white text-primary-700 py-4 rounded-xl font-semibold hover:bg-gray-100 transition flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                      Sending...
                    </>
                  ) : (
                    <>
                      <Send className="w-5 h-5 mr-2" />
                      Send Message
                    </>
                  )}
                </button>

                <p className="text-center text-white/50 text-sm">
                  Or email us directly at{' '}
                  <a href="mailto:contact@whyandkei.com" className="text-primary-300 hover:text-primary-200">
                    contact@whyandkei.com
                  </a>
                </p>
              </form>
            )}
          </motion.div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
