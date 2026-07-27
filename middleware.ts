import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { checkRateLimit } from "@/lib/rate-limit";
import { rateLimitError } from "@/lib/api-error";
import { updateSession } from "@/lib/supabase/middleware";

type RateLimitPolicy = "login" | "publicRead";

function getClientIp(request: NextRequest): string {
  const forwarded = request.headers.get("x-forwarded-for");
  if (forwarded) {
    // x-forwarded-for may contain "client, proxy1, proxy2" — take the first IP
    return forwarded.split(",")[0]!.trim();
  }
  // Fallback for local development where x-forwarded-for may be absent.
  // Using "127.0.0.1" as fallback means local dev shares a single
  // rate-limit bucket, which is acceptable for development.
  return "127.0.0.1";
}

const pathPolicyMap: Record<string, RateLimitPolicy> = {
  "/api/auth": "login",
  "/api/public": "publicRead",
};

function getPolicyForPath(pathname: string): RateLimitPolicy | null {
  for (const [prefix, policy] of Object.entries(pathPolicyMap)) {
    if (pathname.startsWith(prefix)) {
      return policy;
    }
  }
  return null;
}

export async function middleware(request: NextRequest) {
  // 1. Refresh Supabase session (wired for Phase 3e)
  let response = await updateSession(request);

  // 2. Apply rate limiting for matched API paths
  const policy = getPolicyForPath(request.nextUrl.pathname);

  if (policy) {
    const ip = getClientIp(request);
    const { success, reset } = await checkRateLimit(policy, ip);

    if (!success) {
      const error = rateLimitError(reset);
      return NextResponse.json(
        { error: error.error, code: error.code },
        {
          status: error.statusCode,
          headers: {
            "Retry-After": String(error.retryAfter),
          },
        }
      );
    }
  }

  return response;
}

export const config = {
  matcher: ["/api/auth/:path*", "/api/public/:path*"],
};
