import { env } from "./env.mjs";

/** @type {import('next').NextConfig} */
const nextConfig = {};

// env is imported here so T3 Env validation runs at build time.
// If any required variable is missing or malformed, the build fails
// with a clear error naming the offending variable.
env;

export default nextConfig;
