'use client'

import { motion } from 'framer-motion'
import { useRef } from 'react'
import { useInView } from 'framer-motion'
import { Star } from 'lucide-react'

const testimonials = [
  {
    name: 'Sarah Chen',
    role: 'Engineering Manager at Stripe',
    avatar: 'SC',
    content: 'MomentumBar has become essential for managing my distributed team. The day/night indicators are a game-changer for scheduling.',
    rating: 5,
  },
  {
    name: 'Marcus Johnson',
    role: 'Freelance Developer',
    avatar: 'MJ',
    content: 'Finally, a time zone app that doesn\'t look like it\'s from 2010. The Pomodoro timer is a nice bonus for focus sessions.',
    rating: 5,
  },
  {
    name: 'Elena Rodriguez',
    role: 'Product Designer',
    avatar: 'ER',
    content: 'Beautiful design, super intuitive. I love how it integrates with my calendar and shows me my next meeting at a glance.',
    rating: 5,
  },
  {
    name: 'David Park',
    role: 'Remote Team Lead',
    avatar: 'DP',
    content: 'Worth every penny. The ability to group time zones by team makes it so easy to see who\'s available right now.',
    rating: 5,
  },
  {
    name: 'Lisa Thompson',
    role: 'Startup Founder',
    avatar: 'LT',
    content: 'I\'ve tried every time zone app out there. MomentumBar is the only one that got everything right. Clean, fast, and thoughtful.',
    rating: 5,
  },
  {
    name: 'Alex Kim',
    role: 'Software Consultant',
    avatar: 'AK',
    content: 'The theming options are fantastic. It matches my setup perfectly. And the native performance is noticeably snappier than Electron apps.',
    rating: 5,
  },
]

function TestimonialCard({ testimonial, index }: { testimonial: typeof testimonials[0]; index: number }) {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true, margin: '-50px' })

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 30 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 30 }}
      transition={{ duration: 0.5, delay: index * 0.1 }}
      className="bg-white/10 backdrop-blur-xl rounded-2xl p-6 border border-white/20 hover:bg-white/15 transition-all"
    >
      {/* Stars */}
      <div className="flex mb-4">
        {[...Array(testimonial.rating)].map((_, i) => (
          <Star key={i} className="w-5 h-5 text-yellow-400 fill-yellow-400" />
        ))}
      </div>

      {/* Content */}
      <p className="text-white/80 mb-6 leading-relaxed">
        "{testimonial.content}"
      </p>

      {/* Author */}
      <div className="flex items-center">
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary-400 to-purple-500 flex items-center justify-center text-white font-semibold">
          {testimonial.avatar}
        </div>
        <div className="ml-4">
          <p className="font-semibold text-white">{testimonial.name}</p>
          <p className="text-sm text-white/60">{testimonial.role}</p>
        </div>
      </div>
    </motion.div>
  )
}

export default function Testimonials() {
  const headerRef = useRef(null)
  const isHeaderInView = useInView(headerRef, { once: true })

  return (
    <section className="py-24 md:py-32 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <motion.div
          ref={headerRef}
          initial={{ opacity: 0, y: 30 }}
          animate={isHeaderInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 30 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="inline-block px-4 py-2 bg-white/10 backdrop-blur-sm text-white text-sm font-semibold rounded-full mb-4 border border-white/20">
            Testimonials
          </span>
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Loved by Professionals
          </h2>
          <p className="text-xl text-white/70 max-w-2xl mx-auto">
            Join thousands of happy users who transformed their workflow with MomentumBar.
          </p>
        </motion.div>

        {/* Testimonials Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {testimonials.map((testimonial, index) => (
            <TestimonialCard key={testimonial.name} testimonial={testimonial} index={index} />
          ))}
        </div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto"
        >
          {[
            { value: '10K+', label: 'Happy Users' },
            { value: '4.9', label: 'Average Rating' },
            { value: '50+', label: 'Countries' },
            { value: '99%', label: 'Satisfaction' },
          ].map((stat) => (
            <div key={stat.label} className="text-center">
              <p className="text-4xl font-bold text-white mb-2">{stat.value}</p>
              <p className="text-white/60">{stat.label}</p>
            </div>
          ))}
        </motion.div>
      </div>
    </section>
  )
}
