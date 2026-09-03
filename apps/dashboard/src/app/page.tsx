"use client"

import React, { useEffect, useState } from "react"
import Link from "next/link"
import { DashboardLayout } from "@/components/layout/dashboard-layout"
import { useBusiness } from "@/components/providers/business-provider"
import { createClient } from "@/lib/supabase/client"
import type { Database } from "@/types/database.types"
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { CategoryBarChart, CategoryDonutChart } from "@/components/ui/chart"
import { formatCurrency, formatDate, formatLocalDate } from "@/lib/utils"
import {
  TrendingUp,
  TrendingDown,
  Wallet,
  ArrowUpRight,
  ReceiptText,
  Calendar,
  Layers,
  ArrowLeft,
  PlusCircle,
} from "lucide-react"

type Transaction = Database["public"]["Tables"]["transactions"]["Row"] & {
  categories?: { name: string } | null
}

export default function OverviewPage() {
  const { business } = useBusiness()
  const [loading, setLoading] = useState(true)
  const [summary, setSummary] = useState({
    income: 0,
    expense: 0,
    net: 0,
  })
  const [prevSummary, setPrevSummary] = useState({
    income: 0,
    expense: 0,
    net: 0,
  })
  const [recentTransactions, setRecentTransactions] = useState<Transaction[]>([])
  const [expenseBreakdown, setExpenseBreakdown] = useState<
    { name: string; amount: number }[]
  >([])
  const [incomeBreakdown, setIncomeBreakdown] = useState<
    { name: string; amount: number }[]
  >([])

  useEffect(() => {
    if (!business?.id) return

    async function loadOverviewData() {
      try {
        setLoading(true)
        const supabase = createClient()

        // Date calculations: Current month and previous month
        const now = new Date()
        const currentYear = now.getFullYear()
        const currentMonth = now.getMonth()

        // Current month start/end
        const startOfMonth = new Date(currentYear, currentMonth, 1)
        const endOfMonth = new Date(currentYear, currentMonth + 1, 0)
        const startStr = formatLocalDate(startOfMonth)
        const endStr = formatLocalDate(endOfMonth)

        // Previous month start/end
        const prevStartOfMonth = new Date(currentYear, currentMonth - 1, 1)
        const prevEndOfMonth = new Date(currentYear, currentMonth, 0)
        const prevStartStr = formatLocalDate(prevStartOfMonth)
        const prevEndStr = formatLocalDate(prevEndOfMonth)

        // 1. Fetch current month financial summary via RPC
        const { data: summaryData } = await (supabase as any).rpc("get_financial_summary", {
          p_business_id: business!.id,
          p_start_date: startStr,
          p_end_date: endStr,
        })

        if (summaryData && summaryData.length > 0) {
          setSummary({
            income: Number(summaryData[0].total_income || 0),
            expense: Number(summaryData[0].total_expense || 0),
            net: Number(summaryData[0].net || 0),
          })
        }

        // 2. Fetch previous month financial summary
        const { data: prevData } = await (supabase as any).rpc("get_financial_summary", {
          p_business_id: business!.id,
          p_start_date: prevStartStr,
          p_end_date: prevEndStr,
        })

        if (prevData && prevData.length > 0) {
          setPrevSummary({
            income: Number(prevData[0].total_income || 0),
            expense: Number(prevData[0].total_expense || 0),
            net: Number(prevData[0].net || 0),
          })
        }

        // 3. Fetch Category breakdown (expenses)
        const { data: expenseCats } = await (supabase as any).rpc("get_category_breakdown", {
          p_business_id: business!.id,
          p_start_date: startStr,
          p_end_date: endStr,
          p_type: "expense",
        })

        if (expenseCats) {
          setExpenseBreakdown(
            expenseCats.map((c: any) => ({
              name: c.category_name,
              amount: Number(c.total_amount),
            }))
          )
        }

        // 4. Fetch Category breakdown (income)
        const { data: incomeCats } = await (supabase as any).rpc("get_category_breakdown", {
          p_business_id: business!.id,
          p_start_date: startStr,
          p_end_date: endStr,
          p_type: "income",
        })

        if (incomeCats) {
          setIncomeBreakdown(
            incomeCats.map((c: any) => ({
              name: c.category_name,
              amount: Number(c.total_amount),
            }))
          )
        }

        // 5. Fetch Recent Transactions (last 10)
        const { data: txData } = await (supabase as any)
          .from("transactions")
          .select("*, categories(name)")
          .eq("business_id", business!.id)
          .order("date", { ascending: false })
          .order("created_at", { ascending: false })
          .limit(10)

        if (txData) {
          setRecentTransactions(txData as any)
        }
      } catch (err) {
        console.error("Error loading overview data:", err)
      } finally {
        setLoading(false)
      }
    }

    loadOverviewData()
  }, [business?.id])

  // Calculate percentage changes
  const calcChange = (current: number, previous: number) => {
    if (previous === 0) return current > 0 ? "+100%" : "0%"
    const diff = ((current - previous) / previous) * 100
    const sign = diff >= 0 ? "+" : ""
    return `${sign}${diff.toFixed(1)}%`
  }

  const expenseChange = calcChange(summary.expense, prevSummary.expense)
  const incomeChange = calcChange(summary.income, prevSummary.income)

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Top welcome banner */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-gradient-to-r from-emerald-800 via-emerald-700 to-teal-800 rounded-2xl p-6 text-white shadow-sm">
          <div className="space-y-1">
            <div className="flex items-center gap-2 text-emerald-200 text-xs font-semibold">
              <Calendar className="h-3.5 w-3.5" />
              <span>ملخص الشهر الحالي</span>
            </div>
            <h2 className="text-xl md:text-2xl font-bold tracking-tight">
              أهلاً بك في {business?.name}
            </h2>
            <p className="text-xs md:text-sm text-emerald-100/80">
              تابع نشاطك المالي، فواتيرك، وتقارير المصروفات والإيرادات لحظة بلحظة
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Link href="/transactions">
              <Button
                variant="secondary"
                size="sm"
                className="bg-white/10 hover:bg-white/20 text-white border-white/20 text-xs rounded-xl backdrop-blur-xs"
              >
                <ReceiptText className="h-3.5 w-3.5 ml-1.5" />
                عرض كل المعاملات
              </Button>
            </Link>
          </div>
        </div>

        {/* 3 Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Total Income */}
          <Card className="rounded-2xl border-slate-200/80 shadow-xs hover:shadow-md transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <span className="text-xs font-semibold text-slate-500">إجمالي الإيرادات</span>
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600">
                <TrendingUp className="h-5 w-5" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-black text-slate-900">
                {formatCurrency(summary.income, business?.currency)}
              </div>
              <div className="flex items-center gap-1.5 text-xs text-slate-500 mt-2">
                <span className="font-semibold text-emerald-600">{incomeChange}</span>
                <span>مقارنة بالشهر السابق</span>
              </div>
            </CardContent>
          </Card>

          {/* Total Expenses */}
          <Card className="rounded-2xl border-slate-200/80 shadow-xs hover:shadow-md transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <span className="text-xs font-semibold text-slate-500">إجمالي المصروفات</span>
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-red-50 text-red-600">
                <TrendingDown className="h-5 w-5" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-black text-slate-900">
                {formatCurrency(summary.expense, business?.currency)}
              </div>
              <div className="flex items-center gap-1.5 text-xs text-slate-500 mt-2">
                <span className="font-semibold text-red-600">{expenseChange}</span>
                <span>مقارنة بالشهر السابق</span>
              </div>
            </CardContent>
          </Card>

          {/* Net Profit / Balance */}
          <Card className="rounded-2xl border-slate-200/80 shadow-xs hover:shadow-md transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <span className="text-xs font-semibold text-slate-500">صافي الأرباح</span>
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-teal-50 text-teal-600">
                <Wallet className="h-5 w-5" />
              </div>
            </CardHeader>
            <CardContent>
              <div
                className={`text-2xl font-black ${
                  summary.net >= 0 ? "text-emerald-700" : "text-red-700"
                }`}
              >
                {formatCurrency(summary.net, business?.currency)}
              </div>
              <p className="text-xs text-slate-500 mt-2">
                الفرق بين إجمالي الإيرادات والمصروفات
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Charts & Breakdown Section */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Expenses Breakdown Bar Chart */}
          <Card className="lg:col-span-2 rounded-2xl border-slate-200/80 shadow-xs">
            <CardHeader className="flex flex-row items-center justify-between pb-4">
              <div>
                <CardTitle className="text-base font-bold text-slate-900">
                  توزيع المصروفات حسب التصنيف
                </CardTitle>
                <CardDescription className="text-xs text-slate-500 mt-0.5">
                  تفاصيل أكثر بنود الصرف خلال الشهر الحالي
                </CardDescription>
              </div>
              <Layers className="h-4 w-4 text-slate-400" />
            </CardHeader>
            <CardContent>
              <CategoryBarChart
                data={expenseBreakdown}
                currency={business?.currency}
                height={280}
              />
            </CardContent>
          </Card>

          {/* Donut Chart / Category Share */}
          <Card className="rounded-2xl border-slate-200/80 shadow-xs">
            <CardHeader className="pb-2">
              <CardTitle className="text-base font-bold text-slate-900">
                نسب المصروفات
              </CardTitle>
              <CardDescription className="text-xs text-slate-500">
                مخطط دائري يوضح الحصة النسبية
              </CardDescription>
            </CardHeader>
            <CardContent>
              <CategoryDonutChart
                data={expenseBreakdown}
                currency={business?.currency}
                height={220}
              />
            </CardContent>
          </Card>
        </div>

        {/* Recent Transactions Section */}
        <Card className="rounded-2xl border-slate-200/80 shadow-xs">
          <CardHeader className="flex flex-row items-center justify-between pb-3">
            <div>
              <CardTitle className="text-base font-bold text-slate-900">
                آخر المعاملات المسجلة
              </CardTitle>
              <CardDescription className="text-xs text-slate-500 mt-0.5">
                أحدث 10 حركات مالية مسجلة من الموبايل أو الويب
              </CardDescription>
            </div>
            <Link href="/transactions">
              <Button variant="ghost" size="sm" className="text-xs text-emerald-600 gap-1">
                <span>عرض الكل</span>
                <ArrowLeft className="h-3.5 w-3.5" />
              </Button>
            </Link>
          </CardHeader>
          <CardContent>
            {recentTransactions.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-10 text-center">
                <ReceiptText className="h-10 w-10 text-slate-300 mb-2" />
                <p className="text-sm font-semibold text-slate-700">لا توجد معاملات مسجلة حتى الآن</p>
                <p className="text-xs text-slate-500 max-w-sm mt-1">
                  سجل أول معاملة أو التقط صورة فاتورة من تطبيق حسابلي على الموبايل وستظهر هنا فوراً.
                </p>
              </div>
            ) : (
              <div className="divide-y divide-slate-100">
                {recentTransactions.map((tx) => (
                  <div
                    key={tx.id}
                    className="flex items-center justify-between py-3 hover:bg-slate-50/50 px-2 rounded-xl transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl font-bold text-xs ${
                          tx.type === "income"
                            ? "bg-emerald-50 text-emerald-600 border border-emerald-200/60"
                            : "bg-red-50 text-red-600 border border-red-200/60"
                        }`}
                      >
                        {tx.type === "income" ? "+" : "-"}
                      </div>
                      <div className="flex flex-col">
                        <span className="text-sm font-semibold text-slate-800">
                          {tx.vendor_customer_name || tx.categories?.name || "بدون اسم"}
                        </span>
                        <div className="flex items-center gap-2 text-xs text-slate-400">
                          <span>{tx.categories?.name || "عام"}</span>
                          <span>•</span>
                          <span>{formatDate(tx.date)}</span>
                        </div>
                      </div>
                    </div>

                    <div className="text-end">
                      <span
                        className={`text-sm font-bold block ${
                          tx.type === "income"
                            ? "text-emerald-600"
                            : "text-red-600"
                        }`}
                      >
                        {tx.type === "income" ? "+" : "-"}
                        {formatCurrency(Number(tx.amount), business?.currency)}
                      </span>
                      <Badge
                        variant={tx.type === "income" ? "income" : "expense"}
                        className="text-[10px] py-0 px-2 mt-0.5"
                      >
                        {tx.type === "income" ? "إيراد" : "مصروف"}
                      </Badge>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  )
}
