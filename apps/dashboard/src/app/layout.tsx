import type { Metadata } from "next"
import "./globals.css"
import { QueryProvider } from "@/components/providers/query-provider"
import { BusinessProvider } from "@/components/providers/business-provider"

export const metadata: Metadata = {
  title: "حسابلي — لوحة التحكم المالية",
  description: "مساعد إدارة الفواتير والمصروفات الذكي للأنشطة التجارية الصغيرة في مصر",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ar" dir="rtl" className="h-full">
      <body className="min-h-full flex flex-col bg-slate-50 text-slate-900 antialiased font-sans">
        <QueryProvider>
          <BusinessProvider>{children}</BusinessProvider>
        </QueryProvider>
      </body>
    </html>
  )
}
