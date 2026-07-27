export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("@sentry/nextjs/capture-exception");
  }

  if (process.env.NEXT_RUNTIME === "edge") {
    await import("@sentry/nextjs/capture-exception");
  }
}
