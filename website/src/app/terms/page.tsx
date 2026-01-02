'use client'

import { motion } from 'framer-motion'
import { ArrowLeft, FileText } from 'lucide-react'
import Link from 'next/link'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'

export default function TermsPage() {
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
              <FileText className="w-8 h-8 text-white" />
            </div>
            <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
              Terms of Service
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
                  <h2 className="text-2xl font-bold text-white mb-4">1. Acceptance of Terms</h2>
                  <p>
                    By downloading, installing, or using MomentumBar ("the Software"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the Software.
                  </p>
                  <p>
                    These Terms constitute a legal agreement between you and Why&Key Group LLC ("Company," "we," "our," or "us").
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">2. License Grant</h2>
                  <p>
                    Subject to your compliance with these Terms and payment of applicable fees, we grant you a limited, non-exclusive, non-transferable license to:
                  </p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Download and install the Software on the number of Macs specified by your license tier</li>
                    <li>Use the Software for personal or internal business purposes</li>
                  </ul>

                  <h3 className="text-xl font-semibold text-white mb-3 mt-6">License Tiers</h3>
                  <ul className="list-disc pl-6 space-y-2">
                    <li><strong className="text-white">Solo License:</strong> Use on 1 Mac</li>
                    <li><strong className="text-white">Multiple License:</strong> Use on up to 3 Macs</li>
                    <li><strong className="text-white">Enterprise License:</strong> Use on the number of seats specified in your agreement</li>
                  </ul>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">3. License Restrictions</h2>
                  <p>You may NOT:</p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Share your license key with others outside your license tier</li>
                    <li>Sell, rent, lease, or sublicense the Software or your license</li>
                    <li>Reverse engineer, decompile, or disassemble the Software</li>
                    <li>Modify, adapt, or create derivative works of the Software</li>
                    <li>Remove or alter any proprietary notices or labels</li>
                    <li>Use the Software in any way that violates applicable laws</li>
                    <li>Circumvent or attempt to circumvent license validation mechanisms</li>
                  </ul>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">4. Free Trial</h2>
                  <p>
                    We offer a 3-day free trial of the Software. During the trial period, you have access to all features. After the trial expires, you must purchase a license to continue using the Software.
                  </p>
                  <p>
                    No credit card is required for the free trial.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">5. Payment and Refunds</h2>
                  <p>
                    All licenses are sold as one-time purchases with lifetime updates included. Prices are listed in USD and may be subject to applicable taxes.
                  </p>
                  <p className="mt-4">
                    <strong className="text-white">30-Day Money-Back Guarantee:</strong> If you are not satisfied with MomentumBar, you may request a full refund within 30 days of purchase. Contact us at <a href="mailto:contact@whyandkei.com" className="text-primary-300 hover:text-primary-200">contact@whyandkei.com</a> to request a refund.
                  </p>
                  <p className="mt-4">
                    Refunds are processed through the original payment method and may take 5-10 business days to appear.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">6. Updates and Support</h2>
                  <p>
                    Your license includes:
                  </p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>All future updates to the current major version</li>
                    <li>Bug fixes and security patches</li>
                    <li>Email support (response times vary by license tier)</li>
                  </ul>
                  <p className="mt-4">
                    We reserve the right to charge for major version upgrades (e.g., MomentumBar 2.0), but existing license holders will receive a discount.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">7. Intellectual Property</h2>
                  <p>
                    The Software, including all code, graphics, user interface, and documentation, is owned by Why&Key Group LLC and is protected by copyright and other intellectual property laws.
                  </p>
                  <p className="mt-4">
                    "MomentumBar" and the MomentumBar logo are trademarks of Why&Key Group LLC.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">8. Disclaimer of Warranties</h2>
                  <p>
                    THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
                  </p>
                  <p className="mt-4">
                    We do not warrant that the Software will be error-free, uninterrupted, or meet your specific requirements.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">9. Limitation of Liability</h2>
                  <p>
                    TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL WHY&KEY GROUP LLC BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES, WHETHER INCURRED DIRECTLY OR INDIRECTLY, OR ANY LOSS OF DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES.
                  </p>
                  <p className="mt-4">
                    Our total liability for any claims arising from these Terms or your use of the Software shall not exceed the amount you paid for the Software license.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">10. License Revocation</h2>
                  <p>
                    We reserve the right to revoke your license if you:
                  </p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Violate these Terms of Service</li>
                    <li>Engage in fraudulent activity</li>
                    <li>Share your license key beyond your license tier</li>
                    <li>Attempt to circumvent license validation</li>
                  </ul>
                  <p className="mt-4">
                    Upon revocation, you must immediately stop using the Software and delete all copies.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">11. Termination</h2>
                  <p>
                    You may terminate this agreement at any time by deleting all copies of the Software. We may terminate or suspend your license immediately if you breach these Terms.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">12. Governing Law</h2>
                  <p>
                    These Terms shall be governed by and construed in accordance with the laws of the United States, without regard to conflict of law principles.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">13. Changes to Terms</h2>
                  <p>
                    We may update these Terms from time to time. We will notify you of any material changes by posting the new Terms on our website. Your continued use of the Software after such changes constitutes acceptance of the new Terms.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">14. Severability</h2>
                  <p>
                    If any provision of these Terms is found to be unenforceable, the remaining provisions will continue in full force and effect.
                  </p>
                </section>

                <section>
                  <h2 className="text-2xl font-bold text-white mb-4">15. Contact Information</h2>
                  <p>
                    For questions about these Terms, please contact us:
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
