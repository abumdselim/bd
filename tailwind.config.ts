import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "#1a1a2e",
        accent: "#0f3460",
        surface: "#ffffff",
        "surface-alt": "#f1f5f9",
        border: "#e2e8f0",
        "text-primary": "#0f172a",
        "text-secondary": "#16213e",
        "text-muted": "#64748b",
        success: "#16a34a",
        warning: "#f59e0b",
        danger: "#ef4444",
        "dark-bg": "#0f172a",
        "dark-surface": "#1a1a2e",
        "dark-border": "#16213e",
        "dark-text": "#e2e8f0",
      },
      screens: {
        xs: "320px",
        sm: "640px",
        md: "768px",
        lg: "1024px",
        xl: "1280px",
        "2xl": "1536px",
      },
      fontFamily: {
        sans: [
          '"Tiro Bangla"',
          '"Noto Sans Bengali"',
          '"SolaimanLipi"',
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'Roboto',
          'sans-serif',
        ],
      },
    },
  },
  plugins: [],
};

export default config;
