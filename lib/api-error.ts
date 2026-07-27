export interface ApiError {
  error: string;
  code: string;
  statusCode: number;
}

export interface RateLimitErrorResponse extends ApiError {
  retryAfter: number;
}

export function rateLimitError(reset: number): RateLimitErrorResponse {
  return {
    error: "Too many requests. Please try again shortly.",
    code: "RATE_LIMITED",
    statusCode: 429,
    retryAfter: Math.ceil((reset - Date.now()) / 1000),
  };
}
