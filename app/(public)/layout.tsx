export default function PublicLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Inherits <html lang="bn"> from root layout — no override needed
  return <>{children}</>;
}
