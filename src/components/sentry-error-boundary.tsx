'use client';

import * as Sentry from '@sentry/nextjs';
import Error from 'next/error';
import { useEffect } from 'react';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html lang="en">
      <body>
        <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-6">
          <div className="rounded-lg border border-destructive/20 bg-destructive/5 p-6 text-center">
            <h2 className="text-lg font-semibold text-foreground">
              Something went wrong!
            </h2>
            <p className="mt-2 text-sm text-muted-foreground">
              An unexpected error occurred. Our team has been notified.
            </p>
            {error.digest && (
              <p className="mt-1 text-xs text-muted-foreground">
                Error ID: {error.digest}
              </p>
            )}
            <button
              onClick={reset}
              className="mt-4 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
            >
              Try again
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
