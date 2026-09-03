"use client"

import React from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  LayoutDashboard,
  ReceiptText,
  PieChart,
  Tags,
  Settings,
  LogOut,
  Building2,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { useBusiness } from "@/components/providers/business-provider"

const navItems = [
  {
    title: "نظرة عامة",
    href: "/",
    icon: LayoutDashboard,
  },
  {
    title: "المعاملات",
    href: "/transactions",
    icon: ReceiptText,
  },
  {
    title: "التقارير والإحصائيات",
    href: "/reports",
    icon: PieChart,
  },
  {
    title: "التصنيفات",
    href: "/categories",
    icon: Tags,
  },
  {
    title: "الإعدادات",
    href: "/settings",
    icon: Settings,
  },
]

export function Sidebar() {
  const pathname = usePathname()
  const { business, user, signOut } = useBusiness()

  return (
    <aside
      className="hidden md:flex flex-col w-64 border-l border-slate-200 bg-white min-h-screen text-slate-800 shrink-0"
      dir="rtl"
    >
      {/* Brand & Business Logo */}
      <div className="p-6 border-b border-slate-100 flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 text-white font-bold text-lg shadow-sm">
          ح
        </div>
        <div className="flex flex-col overflow-hidden">
          <span className="font-bold text-slate-900 text-base leading-tight">
            حسابلي <span className="text-xs text-emerald-600 font-normal">لوحة الويب</span>
          </span>
          <span className="text-xs text-slate-500 truncate mt-0.5" title={business?.name}>
            {business?.name || "النشاط التجاري"}
          </span>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-4 py-6 space-y-1.5 overflow-y-auto">
        <div className="px-3 pb-2 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
          القائمة الرئيسية
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
              className={cn(
                "flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all duration-150",
                isActive
                  ? "bg-emerald-50 text-emerald-700 font-semibold shadow-xs border border-emerald-100"
                  : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
              )}
            >
              <Icon
                className={cn(
                  "h-4 w-4 shrink-0 transition-colors",
                  isActive ? "text-emerald-600" : "text-slate-400"
                )}
              />
              <span>{item.title}</span>
            </Link>
          )
        })}
      </nav>

      {/* Business info & Profile bottom card */}
      <div className="p-4 border-t border-slate-100 bg-slate-50/50">
        <div className="rounded-xl border border-slate-200/70 bg-white p-3 shadow-xs">
          <div className="flex items-center gap-2.5 mb-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-100/70 text-emerald-800">
              <Building2 className="h-4 w-4" />
            </div>
            <div className="flex flex-col min-w-0 flex-1">
              <span className="text-xs font-semibold text-slate-800 truncate">
                {business?.name}
              </span>
              <span className="text-[11px] text-slate-500 truncate">
                {user?.email || "حساب نشط"}
              </span>
            </div>
          </div>

          <button
            onClick={signOut}
            className="flex w-full items-center justify-center gap-1.5 rounded-lg border border-slate-200 py-1.5 text-xs font-medium text-slate-600 hover:bg-red-50 hover:text-red-600 hover:border-red-200 transition-colors cursor-pointer"
          >
            <LogOut className="h-3.5 w-3.5" />
            <span>تسجيل الخروج</span>
          </button>
        </div>
      </div>
    </aside>
  )
}
