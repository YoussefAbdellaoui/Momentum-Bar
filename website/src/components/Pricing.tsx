"use client";

import { motion } from "framer-motion";
import { useInView } from "framer-motion";
import { useRef } from "react";
import { Check, Sparkles, MessageCircle } from "lucide-react";
import Link from "next/link";

const plans = [
  {
    name: "Solo",
    description: "Perfect for individual users",
    price: 14.99,
    features: [
      "1 Mac license",
      "All features included",
      "Lifetime updates",
      "Email support",
    ],
    popular: false,
    cta: "Get Solo",
    href: "https://buy.stripe.com/YOUR_SOLO_LINK",
    isContact: false,
  },
  {
    name: "Multiple",
    description: "For multi-Mac users",
    price: 24.99,
    features: [
      "Up to 3 Macs",
      "All features included",
      "Lifetime updates",
      "Priority email support",
      "Early access to new features",
    ],
    popular: true,
    cta: "Get Multiple",
    href: "https://buy.stripe.com/YOUR_MULTIPLE_LINK",
    isContact: false,
  },
  {
    name: "Enterprise",
    description: "For teams & organizations",
    price: null,
    priceLabel: "Custom",
    features: [
      "Unlimited team members",
      "All features included",
      "Priority support",
      "Volume discounts",
      "Centralized license management",
      "Custom onboarding",
      "Dedicated account manager",
    ],
    popular: false,
    cta: "Contact Sales",
    href: "/contact?plan=enterprise",
    isContact: true,
  },
];

function PricingCard({
  plan,
  index,
}: {
  plan: (typeof plans)[0];
  index: number;
}) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-50px" });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 50 }}
      animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 50 }}
      transition={{ duration: 0.5, delay: index * 0.15 }}
      className={`relative ${plan.popular ? "md:-mt-4 md:mb-4" : ""}`}
    >
      {/* Popular badge */}
      {plan.popular && (
        <div className="absolute -top-12 left-0 right-0 flex justify-center">
          <span className="inline-flex items-center px-4 py-2 bg-gradient-to-r from-primary-600 to-purple-600 text-white text-sm font-semibold rounded-full shadow-lg">
            <Sparkles className="w-4 h-4 mr-1.5" />
            Most Popular
          </span>
        </div>
      )}

      <div
        className={`h-full rounded-3xl p-8 backdrop-blur-xl ${
          plan.popular
            ? "bg-white/20 border-2 border-white/30 shadow-2xl"
            : "bg-white/10 border border-white/20 hover:bg-white/15 transition-all"
        }`}
      >
        {/* Header */}
        <div className="mb-6">
          <h3 className="text-2xl font-bold mb-2 text-white">{plan.name}</h3>
          <p className="text-white/70">{plan.description}</p>
        </div>

        {/* Price */}
        <div className="mb-8">
          {plan.price ? (
            <div className="flex items-baseline">
              <span className="text-5xl font-bold text-white">
                ${plan.price}
              </span>
              <span className="ml-2 text-white/60">one-time</span>
            </div>
          ) : (
            <div className="flex items-baseline">
              <span className="text-5xl font-bold text-white">
                {plan.priceLabel}
              </span>
            </div>
          )}
        </div>

        {/* Features */}
        <ul className="space-y-4 mb-8">
          {plan.features.map((feature) => (
            <li key={feature} className="flex items-start">
              <Check className="w-5 h-5 mr-3 mt-0.5 flex-shrink-0 text-green-400" />
              <span className="text-white/90">{feature}</span>
            </li>
          ))}
        </ul>

        {/* CTA */}
        {plan.isContact ? (
          <Link
            href={plan.href}
            className="flex items-center justify-center w-full py-4 px-6 rounded-xl font-semibold transition-all bg-white/20 text-white hover:bg-white/30 border border-white/30"
          >
            <MessageCircle className="w-5 h-5 mr-2" />
            {plan.cta}
          </Link>
        ) : (
          <a
            href={plan.href}
            className={`block w-full text-center py-4 px-6 rounded-xl font-semibold transition-all ${
              plan.popular
                ? "bg-white text-primary-700 hover:bg-gray-100 shadow-lg"
                : "bg-white/20 text-white hover:bg-white/30 border border-white/30"
            }`}
          >
            {plan.cta}
          </a>
        )}
      </div>
    </motion.div>
  );
}

export default function Pricing() {
  const headerRef = useRef(null);
  const isHeaderInView = useInView(headerRef, { once: true });

  return (
    <section id="pricing" className="py-24 md:py-32 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <motion.div
          ref={headerRef}
          initial={{ opacity: 0, y: 30 }}
          animate={
            isHeaderInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 30 }
          }
          transition={{ duration: 0.6 }}
          className="text-center mb-16 md:mb-20"
        >
          <span className="inline-block px-4 py-2 bg-white/10 backdrop-blur-sm text-white text-sm font-semibold rounded-full mb-4 border border-white/20">
            Pricing
          </span>
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Simple, One-Time Pricing
          </h2>
          <p className="text-xl text-white/70 max-w-2xl mx-auto">
            Pay once, use forever. No subscriptions, no hidden fees. Just pure
            productivity.
          </p>
        </motion.div>

        {/* Pricing Cards */}
        <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          {plans.map((plan, index) => (
            <PricingCard key={plan.name} plan={plan} index={index} />
          ))}
        </div>

        {/* Money-back guarantee */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5 }}
          className="mt-12 text-center"
        >
          {/* <p className="text-white/60 flex items-center justify-center">
            <svg className="w-5 h-5 mr-2 text-green-400" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            30-day money-back guarantee. No questions asked.
          </p> */}
        </motion.div>
      </div>
    </section>
  );
}
