'use client'

import { motion } from 'framer-motion'
import { useInView } from 'framer-motion'
import { useRef } from 'react'
import {
  Globe,
  Calendar,
  Clock,
  Moon,
  Palette,
  Shield,
  Zap,
  Bell,
  Users
} from 'lucide-react'

const features = [
  {
    icon: Globe,
    title: 'Multi-Time Zone Display',
    description: 'Add unlimited time zones with custom labels. Perfect for tracking team members across the globe.',
  },
  {
    icon: Calendar,
    title: 'Calendar Integration',
    description: 'See your upcoming meetings with one-click join for Zoom, Google Meet, and Teams.',
  },
  {
    icon: Clock,
    title: 'Pomodoro Timer',
    description: 'Built-in focus timer to boost your productivity with customizable work and break intervals.',
  },
  {
    icon: Moon,
    title: 'Day/Night Indicators',
    description: 'Instantly see who\'s awake with accurate sunrise/sunset calculations for each location.',
  },
  {
    icon: Palette,
    title: 'Beautiful Themes',
    description: 'Choose from built-in themes or create your own with custom colors and fonts.',
  },
  {
    icon: Shield,
    title: 'Privacy First',
    description: 'No tracking, no analytics, no data collection. Your data stays on your Mac.',
  },
  {
    icon: Zap,
    title: 'Lightning Fast',
    description: 'Native macOS app built with Swift. Minimal memory footprint, instant response.',
  },
  {
    icon: Bell,
    title: 'Smart Notifications',
    description: 'Get reminders before meetings with quick actions to join or snooze.',
  },
  {
    icon: Users,
    title: 'Team Friendly',
    description: 'Organize time zones by groups. Perfect for managing distributed teams.',
  },
]

function FeatureCard({ feature, index }: { feature: typeof features[0]; index: number }) {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-100px' })

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 50 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 50 }}
      transition={{ duration: 0.5, delay: index * 0.1 }}
      className="group relative"
    >
      <div className="relative h-full bg-white/10 backdrop-blur-xl rounded-2xl p-8 border border-white/20 hover:bg-white/15 hover:border-white/30 transition-all duration-300 hover:-translate-y-1">
        {/* Icon */}
        <div className="w-14 h-14 rounded-xl bg-white/20 flex items-center justify-center mb-6">
          <feature.icon className="w-7 h-7 text-white" />
        </div>

        {/* Content */}
        <h3 className="text-xl font-semibold text-white mb-3">
          {feature.title}
        </h3>
        <p className="text-white/70 leading-relaxed">
          {feature.description}
        </p>
      </div>
    </motion.div>
  )
}

export default function Features() {
  const headerRef = useRef(null)
  const isHeaderInView = useInView(headerRef, { once: true })

  return (
    <section id="features" className="py-24 md:py-32 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <motion.div
          ref={headerRef}
          initial={{ opacity: 0, y: 30 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 30 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16 md:mb-20"
        >
          <span className="inline-block px-4 py-2 bg-white/10 backdrop-blur-sm text-white text-sm font-semibold rounded-full mb-4 border border-white/20">
            Features
          </span>
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Everything You Need
          </h2>
          <p className="text-xl text-white/70 max-w-2xl mx-auto">
            Powerful features designed for productivity, wrapped in a beautiful interface
            that lives right in your menu bar.
          </p>
        </motion.div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
          {features.map((feature, index) => (
            <FeatureCard key={feature.title} feature={feature} index={index} />
          ))}
        </div>
      </div>
    </section>
  )
}
