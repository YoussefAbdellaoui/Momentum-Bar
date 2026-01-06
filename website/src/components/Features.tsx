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
    title: 'World Clock in Your Menu Bar',
    description: 'Track unlimited cities with intelligent sunrise/sunset indicators. Know when your colleagues are awake before you message them.',
  },
  {
    icon: Calendar,
    title: 'Meeting Hub',
    description: 'Connect your calendar and access meeting analytics. See where your time goes and join calls instantly from one click.',
  },
  {
    icon: Clock,
    title: 'Time Zone Math Made Easy',
    description: 'Convert times across zones with natural language. Type "3pm EST" and instantly see it in all your tracked locations.',
  },
  {
    icon: Moon,
    title: 'Context-Aware Intelligence',
    description: 'Visual day/night cycles show real-time local context. Prevent those awkward 3am messages to teammates.',
  },
  {
    icon: Zap,
    title: 'Focus Sessions with Widgets',
    description: 'Launch Pomodoro timers that live in your menu bar and Mac widgets. Your focus timer, always visible, never intrusive.',
  },
  {
    icon: Shield,
    title: 'Zero Cloud, Zero Tracking',
    description: 'Everything runs locally. No accounts, no servers, no data mining. Your schedule and preferences never leave your Mac.',
  },
  {
    icon: Palette,
    title: 'Adaptive Interface',
    description: 'Automatically matches your system theme with custom accent colors. Looks native because it is native.',
  },
  {
    icon: Bell,
    title: 'Intelligent Meeting Reminders',
    description: 'Pre-meeting notifications with one-tap join for Zoom, Meet, and Teams. Your virtual meeting assistant that actually helps.',
  },
  {
    icon: Users,
    title: 'Team Timezone Groups',
    description: 'Create custom groups for different teams and projects. Switch contexts instantly to see what matters now.',
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
            Your Command Center for Time
          </h2>
          <p className="text-xl text-white/70 max-w-2xl mx-auto">
            MomentumBar brings global time awareness, calendar intelligence, and focus tools together
            in one elegant menu bar experience. Built for the way you actually work.
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
