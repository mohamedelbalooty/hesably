import type { Metadata } from "next"
import "./globals.css"
import { IBM_Plex_Sans_Arabic } from "next/font/google"
import { QueryProvider } from "@/components/providers/query-provider"
import { BusinessProvider } from "@/components/providers/business-provider"

export const metadata: Metadata = {
  title: "حسابلي — لوحة التحكم المالية",
  description: "مساعد إدارة الفواتير والمصروفات الذكي للأنشطة التجارية الصغيرة في مصر",
}

const ibmPlexSansArabic = IBM_Plex_Sans_Arabic({
  subsets: ["arabic"],
  weight: ["300", "400", "500", "600", "700"],
  variable: "--font-ibm-plex-sans",
})

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ar" dir="rtl" className={`${ibmPlexSansArabic.variable} h-full`}>
      <body className="min-h-full flex flex-col bg-background text-foreground antialiased font-sans">
        <QueryProvider>
          <BusinessProvider>{children}</BusinessProvider>
        </QueryProvider>
      </body>
    </html>
  )
}
