'use client'

import { motion } from 'framer-motion'
import { ArrowRight, Play, Globe, Clock, Calendar } from 'lucide-react'

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center pt-20">
      {/* Content */}
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="text-center">
          {/* Badge */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="inline-flex items-center px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 mb-8"
          >
            <span className="w-2 h-2 bg-green-400 rounded-full mr-2 animate-pulse" />
            <span className="text-white/90 text-sm">Now available for macOS Sonoma</span>
          </motion.div>

          {/* Headline */}
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-5xl md:text-7xl font-bold text-white mb-6 leading-tight"
          >
            Master Your
            <br />
            <span className="bg-gradient-to-r from-orange-300 via-pink-300 to-purple-300 bg-clip-text text-transparent">
              Time Zones
            </span>
          </motion.h1>

          {/* Subheadline */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="text-xl md:text-2xl text-white/80 mb-10 max-w-3xl mx-auto leading-relaxed"
          >
            The ultimate menu bar app for managing time zones, calendars, and
            scheduling across the globe. Perfect for remote teams.
          </motion.p>

          {/* CTA Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16"
          >
            <a
              href="#download"
              className="group px-8 py-4 bg-white text-primary-700 font-semibold rounded-full hover:bg-gray-100 transition-all hover:shadow-2xl hover:shadow-white/20 flex items-center"
            >
              Download Free Trial
              <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </a>
            <a
              href="#features"
              className="px-8 py-4 bg-white/10 backdrop-blur-sm text-white font-semibold rounded-full border border-white/20 hover:bg-white/20 transition-all flex items-center"
            >
              <Play className="mr-2 w-5 h-5" />
              See Features
            </a>
          </motion.div>

          {/* Floating Features */}
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.4 }}
            className="flex flex-wrap justify-center gap-4 md:gap-8"
          >
            {[
              { icon: Globe, label: 'Unlimited Time Zones' },
              { icon: Calendar, label: 'Calendar Sync' },
              { icon: Clock, label: 'Pomodoro Timer' },
            ].map((feature, index) => (
              <motion.div
                key={feature.label}
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.5, delay: 0.5 + index * 0.1 }}
                className="flex items-center px-5 py-3 bg-white/10 backdrop-blur-sm rounded-full border border-white/20"
              >
                <feature.icon className="w-5 h-5 text-white/80 mr-2" />
                <span className="text-white/90 text-sm font-medium">{feature.label}</span>
              </motion.div>
            ))}
          </motion.div>
        </div>

        {/* App Preview */}
        <motion.div
          initial={{ opacity: 0, y: 60 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.6 }}
          className="mt-20 relative"
        >
          <div className="relative max-w-4xl mx-auto">
            {/* Glow effect */}
            <div className="absolute -inset-4 bg-gradient-to-r from-primary-500/30 to-purple-500/30 rounded-3xl blur-2xl" />

            {/* App mockup */}
            <div className="relative bg-gray-900/80 backdrop-blur-xl rounded-2xl border border-white/10 p-4 shadow-2xl">
              {/* Window controls */}
              <div className="flex items-center space-x-2 mb-4">
                <div className="w-3 h-3 rounded-full bg-red-500" />
                <div className="w-3 h-3 rounded-full bg-yellow-500" />
                <div className="w-3 h-3 rounded-full bg-green-500" />
              </div>

              {/* Content placeholder */}
              <div className="bg-gradient-to-br from-gray-800/50 to-gray-900/50 rounded-lg p-6 space-y-4">
                {/* Time zones mockup */}
                {['San Francisco', 'London', 'Tokyo'].map((city, i) => (
                  <div key={city} className="flex items-center justify-between py-3 border-b border-white/10 last:border-0">
                    <div className="flex items-center">
                      <div className={`w-3 h-3 rounded-full mr-3 ${i === 0 ? 'bg-yellow-400' : i === 1 ? 'bg-blue-400' : 'bg-purple-400'}`} />
                      <span className="text-white font-medium">{city}</span>
                    </div>
                    <span className="text-white/60 font-mono">
                      {i === 0 ? '09:45 AM' : i === 1 ? '05:45 PM' : '02:45 AM'}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Scroll indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2"
      >
        <motion.div
          animate={{ y: [0, 10, 0] }}
          transition={{ duration: 1.5, repeat: Infinity }}
          className="w-6 h-10 rounded-full border-2 border-white/30 flex justify-center pt-2"
        >
          <div className="w-1.5 h-3 bg-white/50 rounded-full" />
        </motion.div>
      </motion.div>
    </section>
  )
}
