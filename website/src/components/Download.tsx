'use client'

import { motion } from 'framer-motion'
import { useRef } from 'react'
import { useInView } from 'framer-motion'
import { Apple, Download, Shield, Zap } from 'lucide-react'

export default function DownloadSection() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true })

  return (
    <section id="download" className="py-24 md:py-32 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Glass card */}
        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 30 }}
          animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 30 }}
          transition={{ duration: 0.6 }}
          className="bg-white/10 backdrop-blur-xl rounded-3xl p-12 md:p-16 border border-white/20 text-center"
        >
          {/* Badge */}
          <div className="inline-flex items-center px-4 py-2 rounded-full bg-white/10 border border-white/20 mb-8">
            <Apple className="w-5 h-5 text-white mr-2" />
            <span className="text-white/90 text-sm">Available for macOS</span>
          </div>

          {/* Headline */}
          <h2 className="text-4xl md:text-6xl font-bold text-white mb-6">
            Try Free for 3 Days
          </h2>
          <p className="text-xl text-white/70 max-w-2xl mx-auto mb-10">
            Download MomentumBar and experience all features free for 3 days.
            No credit card required. No strings attached.
          </p>

          {/* Download Button */}
          <motion.a
            href="/download/MomentumBar.dmg"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="inline-flex items-center px-8 py-4 bg-white text-primary-700 font-semibold rounded-full hover:shadow-2xl hover:shadow-white/20 transition-shadow text-lg"
          >
            <Download className="w-6 h-6 mr-3" />
            Download for macOS
          </motion.a>

          {/* Requirements */}
          <p className="text-white/50 text-sm mt-6">
            Requires macOS 14 Sonoma or later
          </p>

          {/* Trust badges */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={isInView ? { opacity: 1 } : { opacity: 0 }}
            transition={{ delay: 0.4 }}
            className="flex flex-wrap justify-center gap-8 mt-12"
          >
            {[
              { icon: Shield, label: 'Notarized by Apple' },
              { icon: Zap, label: 'Native Swift Performance' },
              { icon: Apple, label: 'Optimized for Apple Silicon' },
            ].map((badge) => (
              <div key={badge.label} className="flex items-center text-white/60">
                <badge.icon className="w-5 h-5 mr-2" />
                <span className="text-sm">{badge.label}</span>
              </div>
            ))}
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}
