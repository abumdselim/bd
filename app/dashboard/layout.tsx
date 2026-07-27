import { SetLang } from "@/components/set-lang";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <SetLang lang="en" />
      {children}
    </>
  );
}
