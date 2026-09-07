module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        navy: '#0F1A3C',
        'dark-navy': '#0A0E27',
        'accent-blue': '#3B82F6',
        'accent-purple': '#8B5CF6',
        'accent-orange': '#F97316',
        'accent-green': '#10B981',
        'accent-yellow': '#FBBF24',
        'glass-light': 'rgba(255, 255, 255, 0.1)',
        'glass-lighter': 'rgba(255, 255, 255, 0.15)',
      },
      backdropBlur: {
        xs: '2px',
      },
      backgroundImage: {
        'gradient-sunset': 'linear-gradient(135deg, #1e3c72 0%, #2a5298 25%, #7e57c2 50%, #f97316 75%, #fbbf24 100%)',
        'gradient-smart-city': 'linear-gradient(180deg, rgba(31, 41, 55, 0.95) 0%, rgba(55, 65, 81, 0.9) 50%, rgba(31, 41, 55, 0.95) 100%)',
      },
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'pulse-glow': 'pulse-glow 2s ease-in-out infinite',
        'slide-up': 'slide-up 0.6s ease-out',
        'fade-in': 'fade-in 0.8s ease-out',
        'count-up': 'count-up 1.5s ease-out',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        'pulse-glow': {
          '0%, 100%': { boxShadow: '0 0 0 0 rgba(59, 130, 246, 0.7)' },
          '50%': { boxShadow: '0 0 0 10px rgba(59, 130, 246, 0)' },
        },
        'slide-up': {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'fade-in': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        'count-up': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
