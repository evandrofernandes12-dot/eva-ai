/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        ink: { 900: '#0b0d12', 800: '#12151c', 700: '#1a1f2a', 600: '#252b39' },
        accent: { DEFAULT: '#7c5cff', soft: '#a897ff' },
      },
    },
  },
  plugins: [],
};
