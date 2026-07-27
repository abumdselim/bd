import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,

  // Performance Monitoring
  tracesSampleRate: 1.0,

  // Session Replay
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,

  // Debug mode (disable in production)
  debug: false,

  integrations: [
    Sentry.replayIntegration({
      maskAllText: true,
      blockAllMedia: true,
    }),
    Sentry.browserTracingIntegration(),
    Sentry.captureConsoleIntegration({
      levels: ["warn", "error"],
    }),
  ],

  // Filter out noisy errors
  ignoreErrors: [
    "ResizeObserver loop limit exceeded",
    "Non-Error promise rejection captured",
    "Cancel rendering route",
    "Navigation cancelled",
  ],

  // Attach user info if available
  beforeSend(event, hint) {
    // Filter out localhost in development
    if (event.server_name?.includes("localhost")) {
      return null;
    }
    return event;
  },
});
