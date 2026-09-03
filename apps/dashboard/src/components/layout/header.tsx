"use client"

import React, { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  Menu,
  X,
  LayoutDashboard,
  ReceiptText,
  PieChart,
  Tags,
  Settings,
  LogOut,
  Building2,
} from "lucide-react"
import { useBusiness } from "@/components/providers/business-provider"
import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

const titles: Record<string, string> = {
  "/": "نظرة عامة على النشاط",
  "/transactions": "سجل المعاملات والفواتير",
  "/reports": "التقارير المالية والتحليلات",
  "/categories": "إدارة تصنيفات المصروفات والإيرادات",
  "/settings": "إعدادات النشاط التجاري والربط",
}

const navItems = [
  { title: "نظرة عامة", href: "/", icon: LayoutDashboard },
  { title: "المعاملات", href: "/transactions", icon: ReceiptText },
  { title: "التقارير", href: "/reports", icon: PieChart },
  { title: "التصنيفات", href: "/categories", icon: Tags },
  { title: "الإعدادات", href: "/settings", icon: Settings },
]

export function Header() {
  const pathname = usePathname()
  const { business, user, signOut } = useBusiness()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  const title = titles[pathname] || "لوحة التحكم"

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b border-slate-200 bg-white/90 backdrop-blur-md px-4 md:px-8">
      {/* Right side in RTL (Title & Breadcrumbs) */}
      <div className="flex items-center gap-3">
        <button
          className="md:hidden p-2 text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        >
          {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </button>
        <div>
          <h1 className="text-base md:text-lg font-bold text-slate-900 leading-tight">
            {title}
          </h1>
        </div>
      </div>

      {/* Left side in RTL (Business badge & Info) */}
      <div className="flex items-center gap-3">
        <Badge variant="secondary" className="hidden sm:flex items-center gap-1.5 py-1 px-3 bg-emerald-50 text-emerald-800 border-emerald-200/60 font-medium text-xs">
          <Building2 className="h-3.5 w-3.5" />
          <span>{business?.name}</span>
          <span className="text-slate-400">({business?.type || "تجاري"})</span>
        </Badge>
      </div>

      {/* Mobile Drawer Navigation */}
      {mobileMenuOpen && (
        <div
          className="fixed inset-0 top-16 z-40 bg-black/40 md:hidden"
          onClick={() => setMobileMenuOpen(false)}
        >
          <div
            className="w-64 bg-white h-full border-l border-slate-200 p-4 space-y-2 shadow-xl"
            dir="rtl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-2 border-b border-slate-100 pb-3 mb-2">
              <p className="font-bold text-sm text-slate-900">{business?.name}</p>
              <p className="text-xs text-slate-500">{user?.email}</p>
            </div>
            {navItems.map((item) => {
              const isActive =
                item.href === "/"
                  ? pathname === "/"
                  : pathname.startsWith(item.href)
              const Icon = item.icon
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium",
                    isActive
                      ? "bg-emerald-50 text-emerald-700 font-semibold"
                      : "text-slate-600 hover:bg-slate-50"
                  )}
                >
                  <Icon className="h-4 w-4" />
                  <span>{item.title}</span>
                </Link>
              )
            })}
            <div className="pt-4 border-t border-slate-100">
              <button
                onClick={signOut}
                className="flex w-full items-center gap-2 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-lg"
              >
                <LogOut className="h-4 w-4" />
                <span>تسجيل الخروج</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </header>
  )
}
