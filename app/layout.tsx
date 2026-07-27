import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "BengalDesk",
  description: "BengalDesk — Bangla-first news desk",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="bn">
      <body className="min-h-screen bg-surface text-text-primary antialiased">
        {children}
      </body>
    </html>
  );
}
