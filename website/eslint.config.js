const nextConfig = require('eslint-config-next/core-web-vitals')

module.exports = [
  ...nextConfig,
  {
    ignores: ['node_modules/**', '.next/**', 'out/**'],
  },
  {
    files: [
      'src/app/privacy/page.tsx',
      'src/app/terms/page.tsx',
      'src/components/Testimonials.tsx',
    ],
    rules: {
      'react/no-unescaped-entities': 'off',
    },
  },
]
