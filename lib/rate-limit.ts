import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";
import { env } from "@/env.mjs";

const redis = new Redis({
  url: env.UPSTASH_REDIS_REST_URL,
  token: env.UPSTASH_REDIS_REST_TOKEN,
});

export const rateLimitPolicies = {
  login: new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(5, "60 s"),
    prefix: "rl:login",
  }),
  publicRead: new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(60, "60 s"),
    prefix: "rl:public",
  }),
  articleSubmit: new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(10, "60 s"),
    prefix: "rl:submit",
  }),
} as const;

export type RateLimitPolicy = keyof typeof rateLimitPolicies;

export async function checkRateLimit(
  policy: RateLimitPolicy,
  identifier: string
) {
  const { success, limit, remaining, reset } =
    await rateLimitPolicies[policy].limit(identifier);
  return { success, limit, remaining, reset };
}
