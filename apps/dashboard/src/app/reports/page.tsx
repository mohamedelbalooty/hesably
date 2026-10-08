"use client"

import React, { useEffect, useState } from "react"
import { DashboardLayout } from "@/components/layout/dashboard-layout"
import { useBusiness } from "@/components/providers/business-provider"
import { createClient } from "@/lib/supabase/client"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { CategoryBarChart, CategoryDonutChart } from "@/components/ui/chart"
import { formatCurrency, formatDate, formatLocalDate } from "@/lib/utils"
import * as XLSX from "xlsx"
import jsPDF from "jspdf"
import autoTable from "jspdf-autotable"
import {
  Download,
  FileSpreadsheet,
  FileText,
  Calendar,
  PieChart as PieIcon,
  TrendingUp,
  TrendingDown,
  Wallet,
  Printer,
} from "lucide-react"

export default function ReportsPage() {
  const { business } = useBusiness()
  const [period, setPeriod] = useState<"this_month" | "last_month" | "ytd" | "custom">(
    "this_month"
  )
  const [startDate, setStartDate] = useState<string>("")
  const [endDate, setEndDate] = useState<string>("")
  const [loading, setLoading] = useState(true)

  const [summary, setSummary] = useState({
    income: 0,
    expense: 0,
    net: 0,
  })
  const [expenseCategories, setExpenseCategories] = useState<
    { name: string; amount: number }[]
  >([])
  const [incomeCategories, setIncomeCategories] = useState<
    { name: string; amount: number }[]
  >([])
  const [transactions, setTransactions] = useState<any[]>([])

  // Calculate Dates based on Period selection
  useEffect(() => {
    const now = new Date()
    const currentYear = now.getFullYear()
    const currentMonth = now.getMonth()

    if (period === "this_month") {
      const s = new Date(currentYear, currentMonth, 1)
      const e = new Date(currentYear, currentMonth + 1, 0)
      setStartDate(formatLocalDate(s))
      setEndDate(formatLocalDate(e))
    } else if (period === "last_month") {
      const s = new Date(currentYear, currentMonth - 1, 1)
      const e = new Date(currentYear, currentMonth, 0)
      setStartDate(formatLocalDate(s))
      setEndDate(formatLocalDate(e))
    } else if (period === "ytd") {
      const s = new Date(currentYear, 0, 1)
      const e = now
      setStartDate(formatLocalDate(s))
      setEndDate(formatLocalDate(e))
    }
  }, [period])

  // Load Report Data
  useEffect(() => {
    if (!business?.id || !startDate || !endDate) return

    async function loadReport() {
      try {
        setLoading(true)
        const supabase = createClient()

        // 1. Fetch Financial Summary RPC
        const { data: sumData } = await (supabase as any).rpc("get_financial_summary", {
          p_business_id: business!.id,
          p_start_date: startDate,
          p_end_date: endDate,
        })

        if (sumData && sumData.length > 0) {
          setSummary({
            income: Number(sumData[0].total_income || 0),
            expense: Number(sumData[0].total_expense || 0),
            net: Number(sumData[0].net || 0),
          })
        } else {
          setSummary({ income: 0, expense: 0, net: 0 })
        }

        // 2. Fetch Expense Category breakdown RPC
        const { data: expData } = await (supabase as any).rpc("get_category_breakdown", {
          p_business_id: business!.id,
          p_start_date: startDate,
          p_end_date: endDate,
          p_type: "expense",
        })
        if (expData) {
          setExpenseCategories(
            expData.map((item: any) => ({
              name: item.category_name,
              amount: Number(item.total_amount),
            }))
          )
        }

        // 3. Fetch Income Category breakdown RPC
        const { data: incData } = await (supabase as any).rpc("get_category_breakdown", {
          p_business_id: business!.id,
          p_start_date: startDate,
          p_end_date: endDate,
          p_type: "income",
        })
        if (incData) {
          setIncomeCategories(
            incData.map((item: any) => ({
              name: item.category_name,
              amount: Number(item.total_amount),
            }))
          )
        }

        // 4. Fetch raw transactions for export
        const { data: txData } = await (supabase as any)
          .from("transactions")
          .select("*, categories(name)")
          .eq("business_id", business!.id)
          .gte("date", startDate)
          .lte("date", endDate)
          .order("date", { ascending: false })

        if (txData) {
          setTransactions(txData)
        }
      } catch (err) {
        console.error(err)
      } finally {
        setLoading(false)
      }
    }

    loadReport()
  }, [business?.id, startDate, endDate])

  // Export to Excel / CSV
  const handleExportExcel = () => {
    if (!transactions.length) {
      alert("لا توجد بيانات لتصديرها في هذه الفترة")
      return
    }

    const rows = transactions.map((t) => ({
      "التاريخ": t.date,
      "النوع": t.type === "income" ? "إيراد" : "مصروف",
      "المبلغ": Number(t.amount),
      "العملة": business?.currency || "EGP",
      "التصنيف": t.categories?.name || "عام",
      "التاجر / العميل": t.vendor_customer_name || "",
      "صورة الفاتورة": t.receipt_image_path ? "مرفقة" : "غير مرفقة",
    }))

    const worksheet = XLSX.utils.json_to_sheet(rows)
    const workbook = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(workbook, worksheet, "المعاملات")

    const filename = `Hesably_Report_${startDate}_${endDate}.xlsx`
    XLSX.writeFile(workbook, filename)
  }

  // Export to PDF
  const handleExportPDF = () => {
    if (!transactions.length) {
      alert("لا توجد بيانات لتصديرها في هذه الفترة")
      return
    }

    const doc = new jsPDF()
    doc.setFontSize(18)
    doc.text(`Hesably Financial Report`, 14, 22)
    doc.setFontSize(11)
    doc.text(`Business: ${business?.name || ""}`, 14, 30)
    doc.text(`Period: ${startDate} to ${endDate}`, 14, 36)
    doc.text(`Total Income: ${summary.income} ${business?.currency || "EGP"}`, 14, 44)
    doc.text(`Total Expense: ${summary.expense} ${business?.currency || "EGP"}`, 14, 50)
    doc.text(`Net: ${summary.net} ${business?.currency || "EGP"}`, 14, 56)

    const tableData = transactions.map((t) => [
      t.date,
      t.type.toUpperCase(),
      `${Number(t.amount)} ${business?.currency || "EGP"}`,
      t.categories?.name || "General",
      t.vendor_customer_name || "-",
    ])

    autoTable(doc, {
      startY: 64,
      head: [["Date", "Type", "Amount", "Category", "Party/Vendor"]],
      body: tableData,
    })

    doc.save(`Hesably_Report_${startDate}_${endDate}.pdf`)
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Top bar with filters and export actions */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight">التقارير المالية</h2>
            <p className="text-xs text-slate-500 mt-0.5">
              تحليل شامل للأداء المالي وتصدير البيانات بصيغ PDF و Excel
            </p>
          </div>

          <div className="flex items-center gap-2">
            <Button
              onClick={handleExportExcel}
              variant="outline"
              size="sm"
              className="text-xs border-slate-300 hover:bg-slate-100 rounded-xl"
            >
              <FileSpreadsheet className="h-3.5 w-3.5 ml-1.5 text-emerald-600" />
              <span>تصدير Excel</span>
            </Button>
            <Button
              onClick={handleExportPDF}
              variant="default"
              size="sm"
              className="text-xs bg-slate-900 hover:bg-slate-800 text-white rounded-xl"
            >
              <FileText className="h-3.5 w-3.5 ml-1.5" />
              <span>تصدير PDF</span>
            </Button>
          </div>
        </div>

        {/* Period Selector Card */}
        <Card className="rounded-2xl border-slate-200/80 shadow-xs">
          <CardContent className="p-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4 text-emerald-600" />
                <span className="text-xs font-bold text-slate-800">اختر الفترة الزمنية:</span>
                <Select
                  value={period}
                  onValueChange={(val: any) => setPeriod(val)}
                >
                  <SelectTrigger className="w-44 text-xs font-semibold">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="this_month">الشهر الحالي</SelectItem>
                    <SelectItem value="last_month">الشهر السابق</SelectItem>
                    <SelectItem value="ytd">منذ بداية العام (YTD)</SelectItem>
                    <SelectItem value="custom">فترة مخصصة</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {period === "custom" && (
                <div className="flex items-center gap-3">
                  <div className="flex items-center gap-1.5 text-xs">
                    <span className="text-slate-500">من:</span>
                    <Input
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                      className="text-xs h-9 w-36"
                    />
                  </div>
                  <div className="flex items-center gap-1.5 text-xs">
                    <span className="text-slate-500">إلى:</span>
                    <Input
                      type="date"
                      value={endDate}
                      onChange={(e) => setEndDate(e.target.value)}
                      className="text-xs h-9 w-36"
                    />
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Financial Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card className="rounded-2xl border-slate-200/80 shadow-xs">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <span className="text-xs font-semibold text-slate-500">إجمالي الإيرادات للفترة</span>
              <TrendingUp className="h-4 w-4 text-emerald-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-black text-emerald-600">
                {formatCurrency(summary.income, business?.currency)}
              </div>
            </CardContent>
          </Card>

          <Card className="rounded-2xl border-slate-200/80 shadow-xs">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <span className="text-xs font-semibold text-slate-500">إجمالي المصروفات للفترة</span>
              <TrendingDown className="h-4 w-4 text-red-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-black text-red-600">
                {formatCurrency(summary.expense, business?.currency)}
              </div>
            </CardContent>
          </Card>

          <Card className="rounded-2xl border-slate-200/80 shadow-xs">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <span className="text-xs font-semibold text-slate-500">صافي الفترة</span>
              <Wallet className="h-4 w-4 text-teal-600" />
            </CardHeader>
            <CardContent>
              <div
                className={`text-2xl font-black ${
                  summary.net >= 0 ? "text-emerald-700" : "text-red-700"
                }`}
              >
                {formatCurrency(summary.net, business?.currency)}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Breakdown Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Expense Categories Bar Chart */}
          <Card className="rounded-2xl border-slate-200/80 shadow-xs">
            <CardHeader>
              <CardTitle className="text-base font-bold text-slate-900">
                توزيع بنود المصروفات
              </CardTitle>
              <CardDescription className="text-xs text-slate-500">
                المبالغ المصروفة مقسمة حسب التصنيف
              </CardDescription>
            </CardHeader>
            <CardContent>
              <CategoryBarChart
                data={expenseCategories}
                currency={business?.currency}
                height={260}
              />
            </CardContent>
          </Card>

          {/* Income Categories Donut Chart */}
          <Card className="rounded-2xl border-slate-200/80 shadow-xs">
            <CardHeader>
              <CardTitle className="text-base font-bold text-slate-900">
                توزيع مصادر الإيرادات
              </CardTitle>
              <CardDescription className="text-xs text-slate-500">
                الحصة النسبية لكل بند إيراد
              </CardDescription>
            </CardHeader>
            <CardContent>
              <CategoryDonutChart
                data={incomeCategories}
                currency={business?.currency}
                height={260}
              />
            </CardContent>
          </Card>
        </div>
      </div>
    </DashboardLayout>
  )
}
