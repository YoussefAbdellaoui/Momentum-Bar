'use client'

import { motion } from 'framer-motion'
import { ArrowLeft, Shield } from 'lucide-react'
import Link from 'next/link'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'

export default function PrivacyPage() {
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
            <div className="w-16 h-16 bg-white/10 rounded-2xl flex items-center justify-center mx-auto mb-6 border border-white/20">
              <Shield className="w-8 h-8 text-white" />
            </div>
            <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
              Privacy Policy
            </h1>
            <p className="text-white/60">
              Last updated: January 2025
            </p>
          </motion.div>

          {/* Content */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white/10 backdrop-blur-xl rounded-3xl p-8 md:p-10 border border-white/20"
          >
            <div className="prose prose-invert prose-lg max-w-none">
              <div className="space-y-8 text-white/80">
                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Introduction</h2>
                  <p>
                    Why&Key Group LLC ("we," "our," or "us") operates MomentumBar, a macOS menu bar application for time zone and calendar management. This Privacy Policy explains how we collect, use, and protect your information when you use our application and services.
                  </p>
                  <p>
                    We are committed to protecting your privacy and being transparent about our data practices. MomentumBar is designed with privacy as a core principle.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Information We Collect</h2>

                  <h3 className="text-xl font-semibold text-white mb-3">Data Stored Locally on Your Device</h3>
                  <p>MomentumBar stores all your preferences and settings locally on your Mac:</p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Time zone configurations and custom labels</li>
                    <li>Display preferences (themes, fonts, formats)</li>
                    <li>Calendar integration settings</li>
                    <li>Pomodoro timer configurations</li>
                    <li>Application preferences</li>
                  </ul>
                  <p className="mt-4">
                    <strong className="text-white">This data never leaves your device</strong> and is not transmitted to our servers or any third parties.
                  </p>

                  <h3 className="text-xl font-semibold text-white mb-3 mt-6">License Verification Data</h3>
                  <p>When you activate a license, we collect:</p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Email address (provided at purchase)</li>
                    <li>License key</li>
                    <li>Hardware identifier (a hashed, non-reversible ID unique to your Mac)</li>
                    <li>Machine name (e.g., "John's MacBook Pro")</li>
                  </ul>
                  <p className="mt-4">
                    This information is used solely for license validation and preventing unauthorized use.
                  </p>

                  <h3 className="text-xl font-semibold text-white mb-3 mt-6">Purchase Information</h3>
                  <p>
                    Purchases are processed through Dodo Payments. We receive your email address and purchase details, but we do not have access to your payment card information.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Information We Do NOT Collect</h2>
                  <p>MomentumBar does not collect:</p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Calendar event contents or details</li>
                    <li>Meeting names, participants, or descriptions</li>
                    <li>Your contacts or address book</li>
                    <li>Usage analytics or telemetry</li>
                    <li>Location data (beyond time zone settings you configure)</li>
                    <li>Any personal files or documents</li>
                    <li>Browsing history or internet activity</li>
                  </ul>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Calendar Access</h2>
                  <p>
                    MomentumBar requests access to your calendar solely to display upcoming events in the menu bar and provide meeting reminders. Calendar data is:
                  </p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Read locally on your device</li>
                    <li>Never transmitted to our servers</li>
                    <li>Never shared with third parties</li>
                    <li>Only used to display event information in the app</li>
                  </ul>
                  <p className="mt-4">
                    You can revoke calendar access at any time through macOS System Settings.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">How We Use Your Information</h2>
                  <p>We use the limited information we collect to:</p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Validate and manage your software license</li>
                    <li>Send you your license key after purchase</li>
                    <li>Provide customer support when you contact us</li>
                    <li>Send important product updates (you can opt out)</li>
                  </ul>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Data Security</h2>
                  <p>
                    We implement industry-standard security measures to protect your information:
                  </p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>License data is stored securely in your Mac's Keychain</li>
                    <li>Hardware identifiers are hashed and cannot be reversed</li>
                    <li>All server communications use HTTPS encryption</li>
                    <li>We use secure, reputable third-party services (Dodo Payments for payments, Resend for email)</li>
                  </ul>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Third-Party Services</h2>
                  <p>We use the following third-party services:</p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li><strong className="text-white">Dodo Payments</strong> - Payment processing (<a href="https://dodopayments.com/privacy-policy" className="text-primary-300 hover:text-primary-200">Privacy Policy</a>)</li>
                    <li><strong className="text-white">Resend</strong> - Email delivery (<a href="https://resend.com/privacy" className="text-primary-300 hover:text-primary-200">Privacy Policy</a>)</li>
                  </ul>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Data Retention</h2>
                  <p>
                    We retain license information for the duration of your license validity. If you request deletion of your data, we will remove your information within 30 days, except where we are required to retain it for legal or accounting purposes.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Your Rights</h2>
                  <p>You have the right to:</p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Request access to your personal data</li>
                    <li>Request correction of inaccurate data</li>
                    <li>Request deletion of your data</li>
                    <li>Deactivate your license from your machine</li>
                    <li>Opt out of marketing communications</li>
                  </ul>
                  <p className="mt-4">
                    To exercise these rights, contact us at <a href="mailto:contact@whyandkei.com" className="text-primary-300 hover:text-primary-200">contact@whyandkei.com</a>.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Children's Privacy</h2>
                  <p>
                    MomentumBar is not intended for children under 13. We do not knowingly collect information from children under 13.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Changes to This Policy</h2>
                  <p>
                    We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new policy on our website and updating the "Last updated" date.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">Contact Us</h2>
                  <p>
                    If you have any questions about this Privacy Policy, please contact us:
                  </p>
                  <p className="mt-4">
                    <strong className="text-white">Why&Key Group LLC</strong><br />
                    Email: <a href="mailto:contact@whyandkei.com" className="text-primary-300 hover:text-primary-200">contact@whyandkei.com</a>
                  </p>
                </section>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
