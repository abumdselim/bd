import { SetLang } from "@/components/set-lang";

export default function AdminLayout({
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
