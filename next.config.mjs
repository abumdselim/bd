import { env } from "./env.mjs";

const cspDirectives = {
  "default-src": ["'self'"],
  "script-src": ["'self'", "'unsafe-inline'", "https://va.vercel-scripts.com"],
  "style-src": ["'self'", "'unsafe-inline'"],
  "img-src": ["'self'", "data:", "https://*.supabase.co"],
  "font-src": ["'self'", "data:"],
  "connect-src": [
    "'self'",
    "https://*.supabase.co",
    "wss://*.supabase.co",
    "https://va.vercel-scripts.com",
  ],
  "frame-ancestors": ["'none'"],
  "base-uri": ["'self'"],
  "form-action": ["'self'"],
  "object-src": ["'none'"],
};

const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=()",
  },
  {
    key: "Content-Security-Policy",
    value: Object.entries(cspDirectives)
      .map(([k, v]) => `${k} ${v.join(" ")}`)
      .join("; "),
  },
];

/** @type {import('next').NextConfig} */
const nextConfig = {
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: securityHeaders,
      },
    ];
  },
};

// env is imported here so T3 Env validation runs at build time.
// If any required variable is missing or malformed, the build fails
// with a clear error naming the offending variable.
env;

export default nextConfig;
