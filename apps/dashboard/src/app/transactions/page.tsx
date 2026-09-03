"use client"

import React, { useEffect, useState, useMemo } from "react"
import { DashboardLayout } from "@/components/layout/dashboard-layout"
import { useBusiness } from "@/components/providers/business-provider"
import { createClient } from "@/lib/supabase/client"
import type { Database } from "@/types/database.types"
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import {
  Table,
  TableHeader,
  TableBody,
  TableHead,
  TableRow,
  TableCell,
} from "@/components/ui/table"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { formatCurrency, formatDate } from "@/lib/utils"
import {
  Search,
  Filter,
  Plus,
  Trash2,
  Edit2,
  FileImage,
  ExternalLink,
  ReceiptText,
  Calendar,
  Layers,
  ArrowUpDown,
  X,
  Eye,
} from "lucide-react"

type Transaction = Database["public"]["Tables"]["transactions"]["Row"] & {
  categories?: { name: string } | null
}
type Category = Database["public"]["Tables"]["categories"]["Row"]

export default function TransactionsPage() {
  const { business } = useBusiness()
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)

  // Filters state
  const [searchTerm, setSearchTerm] = useState("")
  const [typeFilter, setTypeFilter] = useState<string>("all")
  const [categoryFilter, setCategoryFilter] = useState<string>("all")
  const [dateFilter, setDateFilter] = useState<string>("all")

  // Selected transaction for view/edit
  const [selectedTx, setSelectedTx] = useState<Transaction | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [isEditing, setIsEditing] = useState(false)
  const [isDeleteConfirmOpen, setIsDeleteConfirmOpen] = useState(false)
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)

  // Edit/Add Form State
  const [formAmount, setFormAmount] = useState<string>("")
  const [formType, setFormType] = useState<"income" | "expense">("expense")
  const [formDate, setFormDate] = useState<string>("")
  const [formCategoryId, setFormCategoryId] = useState<string>("")
  const [formVendorName, setFormVendorName] = useState<string>("")
  const [formError, setFormError] = useState<string | null>(null)
  const [isSaving, setIsSaving] = useState(false)

  // Signed URL for receipt image
  const [receiptImageUrl, setReceiptImageUrl] = useState<string | null>(null)

  // Load Transactions and Categories
  const loadData = async () => {
    if (!business?.id) {
      setLoading(false)
      return
    }
    try {
      setLoading(true)
      const supabase = createClient()

      // Fetch Categories
      const { data: catData } = await (supabase as any)
        .from("categories")
        .select("*")
        .eq("business_id", business.id)
        .order("name")

      if (catData) setCategories(catData)

      // Fetch Transactions
      const { data: txData, error } = await (supabase as any)
        .from("transactions")
        .select("*, categories(name)")
        .eq("business_id", business.id)
        .order("date", { ascending: false })
        .order("created_at", { ascending: false })

      if (error) {
        console.error("Error loading transactions:", error)
      } else if (txData) {
        setTransactions(txData as any)
      }
    } catch (err) {
      console.error("Error in loadData:", err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [business?.id])

  // Get Signed URL for receipt if available
  useEffect(() => {
    async function getReceiptUrl() {
      if (selectedTx?.receipt_image_path) {
        const supabase = createClient()
        const { data } = await supabase.storage
          .from("receipts")
          .createSignedUrl(selectedTx.receipt_image_path, 3600)
        setReceiptImageUrl(data?.signedUrl || null)
      } else {
        setReceiptImageUrl(null)
      }
    }
    if (selectedTx) {
      getReceiptUrl()
    }
  }, [selectedTx])

  // Filter transactions
  const filteredTransactions = useMemo(() => {
    return transactions.filter((tx) => {
      // 1. Search filter (vendor/customer name)
      if (searchTerm) {
        const term = searchTerm.toLowerCase()
        const vendor = (tx.vendor_customer_name || "").toLowerCase()
        const cat = (tx.categories?.name || "").toLowerCase()
        if (!vendor.includes(term) && !cat.includes(term)) {
          return false
        }
      }

      // 2. Type filter
      if (typeFilter !== "all" && tx.type !== typeFilter) {
        return false
      }

      // 3. Category filter
      if (categoryFilter !== "all" && tx.category_id !== categoryFilter) {
        return false
      }

      // 4. Date filter
      if (dateFilter !== "all") {
        const txDate = new Date(tx.date)
        const now = new Date()
        if (dateFilter === "today") {
          const todayStr = now.toISOString().split("T")[0]
          if (tx.date !== todayStr) return false
        } else if (dateFilter === "this_month") {
          if (
            txDate.getMonth() !== now.getMonth() ||
            txDate.getFullYear() !== now.getFullYear()
          ) {
            return false
          }
        } else if (dateFilter === "last_month") {
          const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1)
          if (
            txDate.getMonth() !== lastMonth.getMonth() ||
            txDate.getFullYear() !== lastMonth.getFullYear()
          ) {
            return false
          }
        }
      }

      return true
    })
  }, [transactions, searchTerm, typeFilter, categoryFilter, dateFilter])

  // Open Detail / Edit
  const handleOpenDetail = (tx: Transaction) => {
    setSelectedTx(tx)
    setFormAmount(String(tx.amount))
    setFormType(tx.type)
    setFormDate(tx.date)
    setFormCategoryId(tx.category_id)
    setFormVendorName(tx.vendor_customer_name || "")
    setIsEditing(false)
    setFormError(null)
    setIsDetailOpen(true)
  }

  // Open Add Dialog
  const handleOpenAdd = () => {
    setFormAmount("")
    setFormType("expense")
    setFormDate(new Date().toISOString().split("T")[0])
    setFormCategoryId(categories[0]?.id || "")
    setFormVendorName("")
    setFormError(null)
    setIsAddModalOpen(true)
  }

  // Save Edit Transaction
  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedTx || !business?.id) return

    const parsedAmount = parseFloat(formAmount)
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      setFormError("يرجى إدخال مبلغ صحيح أكبر من الصفر")
      return
    }
    if (!formDate) {
      setFormError("يرجى تحديد التاريخ")
      return
    }
    if (!formCategoryId) {
      setFormError("يرجى اختيار التصنيف")
      return
    }

    try {
      setIsSaving(true)
      setFormError(null)
      const supabase = createClient()

      const { error } = await (supabase as any)
        .from("transactions")
        .update({
          amount: parsedAmount,
          type: formType,
          date: formDate,
          category_id: formCategoryId,
          vendor_customer_name: formVendorName.trim() || null,
        })
        .eq("id", selectedTx.id)
        .eq("business_id", business.id)

      if (error) {
        setFormError(error.message || "فشل تحديث المعاملة")
        return
      }

      // Refresh data
      await loadData()
      setIsDetailOpen(false)
    } catch (err: any) {
      setFormError(err?.message || "حدث خطأ غير متوقع")
    } finally {
      setIsSaving(false)
    }
  }

  // Save New Transaction
  const handleSaveAdd = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!business?.id) return

    const parsedAmount = parseFloat(formAmount)
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      setFormError("يرجى إدخال مبلغ صحيح أكبر من الصفر")
      return
    }
    if (!formDate) {
      setFormError("يرجى تحديد التاريخ")
      return
    }
    if (!formCategoryId) {
      setFormError("يرجى اختيار التصنيف")
      return
    }

    try {
      setIsSaving(true)
      setFormError(null)
      const supabase = createClient()

      const { error } = await (supabase as any).from("transactions").insert({
        business_id: business.id,
        amount: parsedAmount,
        type: formType,
        date: formDate,
        category_id: formCategoryId,
        vendor_customer_name: formVendorName.trim() || null,
      })

      if (error) {
        setFormError(error.message || "فشل إضافة المعاملة")
        return
      }

      await loadData()
      setIsAddModalOpen(false)
    } catch (err: any) {
      setFormError(err?.message || "حدث خطأ غير متوقع")
    } finally {
      setIsSaving(false)
    }
  }

  // Delete Transaction
  const handleDeleteTransaction = async () => {
    if (!selectedTx || !business?.id) return

    try {
      setIsSaving(true)
      const supabase = createClient()
      const { error } = await (supabase as any)
        .from("transactions")
        .delete()
        .eq("id", selectedTx.id)
        .eq("business_id", business.id)

      if (error) {
        console.error("Delete error:", error)
        return
      }

      await loadData()
      setIsDeleteConfirmOpen(false)
      setIsDetailOpen(false)
    } catch (err) {
      console.error(err)
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header bar */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight">سجل المعاملات</h2>
            <p className="text-xs text-slate-500 mt-0.5">
              عرض، تصفية، تعديل، وحذف المعاملات المسجلة
            </p>
          </div>
          <Button
            onClick={handleOpenAdd}
            className="bg-emerald-600 hover:bg-emerald-700 text-white gap-2 shadow-xs rounded-xl"
          >
            <Plus className="h-4 w-4" />
            <span>إضافة معاملة يدوياً</span>
          </Button>
        </div>

        {/* Filters Bar */}
        <Card className="rounded-2xl border-slate-200/80 shadow-xs">
          <CardContent className="p-4 space-y-3">
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3">
              {/* Search Bar */}
              <div className="relative">
                <Input
                  placeholder="ابحث بالاسم أو التصنيف..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pr-9 text-xs"
                />
                <Search className="absolute right-3 top-2.5 h-4 w-4 text-slate-400 pointer-events-none" />
              </div>

              {/* Type Filter */}
              <Select value={typeFilter} onValueChange={setTypeFilter}>
                <SelectTrigger className="text-xs">
                  <SelectValue placeholder="النوع: الكل" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">كل الأنواع</SelectItem>
                  <SelectItem value="expense">مصروفات فقط</SelectItem>
                  <SelectItem value="income">إيرادات فقط</SelectItem>
                </SelectContent>
              </Select>

              {/* Category Filter */}
              <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                <SelectTrigger className="text-xs">
                  <SelectValue placeholder="التصنيف: الكل" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">كل التصنيفات</SelectItem>
                  {categories.map((cat) => (
                    <SelectItem key={cat.id} value={cat.id}>
                      {cat.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>

              {/* Date Period Filter */}
              <Select value={dateFilter} onValueChange={setDateFilter}>
                <SelectTrigger className="text-xs">
                  <SelectValue placeholder="الفترة: الكل" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">كل الأوقات</SelectItem>
                  <SelectItem value="today">اليوم</SelectItem>
                  <SelectItem value="this_month">الشهر الحالي</SelectItem>
                  <SelectItem value="last_month">الشهر السابق</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {/* Transactions Table */}
        <Card className="rounded-2xl border-slate-200/80 shadow-xs overflow-hidden">
          <CardContent className="p-0">
            {loading ? (
              <div className="flex flex-col items-center justify-center py-16">
                <div className="h-8 w-8 animate-spin rounded-full border-3 border-emerald-600 border-t-transparent mb-2" />
                <p className="text-xs text-slate-500">جاري تحميل المعاملات...</p>
              </div>
            ) : filteredTransactions.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16 text-center px-4">
                <ReceiptText className="h-12 w-12 text-slate-300 mb-3" />
                <p className="text-sm font-semibold text-slate-700">لم يتم العثور على أي معاملات</p>
                <p className="text-xs text-slate-500 max-w-sm mt-1">
                  جرب تغيير خيارات التصفية أو أضف معاملة جديدة.
                </p>
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>التاريخ</TableHead>
                    <TableHead>النوع</TableHead>
                    <TableHead>البيان / الطرف</TableHead>
                    <TableHead>التصنيف</TableHead>
                    <TableHead>المبلغ</TableHead>
                    <TableHead>الفاتورة</TableHead>
                    <TableHead className="text-end">الإجراءات</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredTransactions.map((tx) => (
                    <TableRow
                      key={tx.id}
                      className="cursor-pointer hover:bg-slate-50/70"
                      onClick={() => handleOpenDetail(tx)}
                    >
                      <TableCell className="font-medium text-xs text-slate-700 whitespace-nowrap">
                        {formatDate(tx.date)}
                      </TableCell>
                      <TableCell>
                        <Badge
                          variant={tx.type === "income" ? "income" : "expense"}
                          className="text-[11px]"
                        >
                          {tx.type === "income" ? "إيراد" : "مصروف"}
                        </Badge>
                      </TableCell>
                      <TableCell className="font-semibold text-xs text-slate-900">
                        {tx.vendor_customer_name || "—"}
                      </TableCell>
                      <TableCell className="text-xs text-slate-600">
                        {tx.categories?.name || "عام"}
                      </TableCell>
                      <TableCell
                        className={`text-xs font-bold whitespace-nowrap ${
                          tx.type === "income" ? "text-emerald-600" : "text-red-600"
                        }`}
                      >
                        {tx.type === "income" ? "+" : "-"}
                        {formatCurrency(Number(tx.amount), business?.currency)}
                      </TableCell>
                      <TableCell>
                        {tx.receipt_image_path ? (
                          <div className="flex items-center gap-1 text-emerald-600 text-xs font-medium">
                            <FileImage className="h-3.5 w-3.5" />
                            <span>مرفقة</span>
                          </div>
                        ) : (
                          <span className="text-slate-400 text-xs">—</span>
                        )}
                      </TableCell>
                      <TableCell className="text-end">
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-8 px-2 text-xs text-slate-600 hover:text-emerald-700"
                          onClick={(e) => {
                            e.stopPropagation()
                            handleOpenDetail(tx)
                          }}
                        >
                          <Eye className="h-3.5 w-3.5 ml-1" />
                          <span>عرض</span>
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        {/* Transaction Detail / Edit Dialog */}
        <Dialog open={isDetailOpen} onOpenChange={setIsDetailOpen}>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle className="text-lg font-bold text-slate-900">
                {isEditing ? "تعديل المعاملة" : "تفاصيل المعاملة"}
              </DialogTitle>
              <DialogDescription className="text-xs text-slate-500">
                {isEditing
                  ? "قم بتعديل البيانات وحفظ التغييرات"
                  : "مراجعة تفاصيل الفاتورة والمستند المرفق"}
              </DialogDescription>
            </DialogHeader>

            {formError && (
              <div className="rounded-xl border border-red-200 bg-red-50 p-2.5 text-xs text-red-700">
                {formError}
              </div>
            )}

            {isEditing ? (
              <form onSubmit={handleSaveEdit} className="space-y-3 pt-2">
                <div className="space-y-1">
                  <Label htmlFor="edit-amount" className="text-xs font-semibold">
                    المبلغ ({business?.currency || "EGP"})
                  </Label>
                  <Input
                    id="edit-amount"
                    type="number"
                    step="0.01"
                    required
                    value={formAmount}
                    onChange={(e) => setFormAmount(e.target.value)}
                    dir="ltr"
                    className="text-start"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <Label htmlFor="edit-type" className="text-xs font-semibold">
                      النوع
                    </Label>
                    <Select
                      value={formType}
                      onValueChange={(val: any) => setFormType(val)}
                    >
                      <SelectTrigger id="edit-type" className="text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="expense">مصروف</SelectItem>
                        <SelectItem value="income">إيراد</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="edit-date" className="text-xs font-semibold">
                      التاريخ
                    </Label>
                    <Input
                      id="edit-date"
                      type="date"
                      required
                      value={formDate}
                      onChange={(e) => setFormDate(e.target.value)}
                      className="text-xs"
                    />
                  </div>
                </div>

                <div className="space-y-1">
                  <Label htmlFor="edit-cat" className="text-xs font-semibold">
                    التصنيف
                  </Label>
                  <Select
                    value={formCategoryId}
                    onValueChange={setFormCategoryId}
                  >
                    <SelectTrigger id="edit-cat" className="text-xs">
                      <SelectValue placeholder="اختر التصنيف" />
                    </SelectTrigger>
                    <SelectContent>
                      {categories.map((c) => (
                        <SelectItem key={c.id} value={c.id}>
                          {c.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-1">
                  <Label htmlFor="edit-vendor" className="text-xs font-semibold">
                    اسم التاجر / العميل
                  </Label>
                  <Input
                    id="edit-vendor"
                    value={formVendorName}
                    onChange={(e) => setFormVendorName(e.target.value)}
                    placeholder="مثال: شركة النور أو عميل نقدي"
                    className="text-xs"
                  />
                </div>

                <DialogFooter className="pt-3 gap-2">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => setIsEditing(false)}
                    disabled={isSaving}
                  >
                    إلغاء التعديل
                  </Button>
                  <Button
                    type="submit"
                    size="sm"
                    className="bg-emerald-600 hover:bg-emerald-700 text-white"
                    disabled={isSaving}
                  >
                    {isSaving ? "جاري الحفظ..." : "حفظ التغييرات"}
                  </Button>
                </DialogFooter>
              </form>
            ) : (
              <div className="space-y-4 pt-2">
                {/* Details view */}
                <div className="grid grid-cols-2 gap-3 bg-slate-50 p-3 rounded-xl border border-slate-100 text-xs">
                  <div>
                    <span className="text-slate-400 block text-[11px]">المبلغ:</span>
                    <span
                      className={`font-black text-base ${
                        selectedTx?.type === "income"
                          ? "text-emerald-600"
                          : "text-red-600"
                      }`}
                    >
                      {formatCurrency(
                        Number(selectedTx?.amount || 0),
                        business?.currency
                      )}
                    </span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px]">النوع:</span>
                    <Badge
                      variant={
                        selectedTx?.type === "income" ? "income" : "expense"
                      }
                      className="mt-0.5"
                    >
                      {selectedTx?.type === "income" ? "إيراد" : "مصروف"}
                    </Badge>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px]">التاريخ:</span>
                    <span className="font-semibold text-slate-800">
                      {formatDate(selectedTx?.date || "")}
                    </span>
                  </div>
                  <div>
                    <span className="text-slate-400 block text-[11px]">التصنيف:</span>
                    <span className="font-semibold text-slate-800">
                      {selectedTx?.categories?.name || "عام"}
                    </span>
                  </div>
                  <div className="col-span-2">
                    <span className="text-slate-400 block text-[11px]">
                      التاجر / العميل:
                    </span>
                    <span className="font-semibold text-slate-800">
                      {selectedTx?.vendor_customer_name || "—"}
                    </span>
                  </div>
                </div>

                {/* Receipt Image Viewer */}
                {receiptImageUrl && (
                  <div className="space-y-1.5">
                    <span className="text-xs font-semibold text-slate-700 block">
                      صورة الفاتورة المرفقة:
                    </span>
                    <div className="relative rounded-xl border border-slate-200 overflow-hidden bg-slate-100 flex items-center justify-center max-h-56">
                      <img
                        src={receiptImageUrl}
                        alt="Receipt"
                        className="object-contain max-h-56 w-full"
                      />
                    </div>
                  </div>
                )}

                <DialogFooter className="pt-2 flex justify-between gap-2">
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => setIsDeleteConfirmOpen(true)}
                  >
                    <Trash2 className="h-3.5 w-3.5 ml-1" />
                    حذف المعاملة
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setIsEditing(true)}
                  >
                    <Edit2 className="h-3.5 w-3.5 ml-1" />
                    تعديل البيانات
                  </Button>
                </DialogFooter>
              </div>
            )}
          </DialogContent>
        </Dialog>

        {/* Delete Confirmation Dialog */}
        <Dialog
          open={isDeleteConfirmOpen}
          onOpenChange={setIsDeleteConfirmOpen}
        >
          <DialogContent className="max-w-sm">
            <DialogHeader>
              <DialogTitle className="text-base font-bold text-slate-900">
                تأكيد حذف المعاملة
              </DialogTitle>
              <DialogDescription className="text-xs text-slate-500">
                هل أنت متأكد من رغبتك في حذف هذه المعاملة نهائياً؟ لن تتمكن من التراجع عن هذا الإجراء.
              </DialogDescription>
            </DialogHeader>
            <DialogFooter className="pt-3 gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setIsDeleteConfirmOpen(false)}
                disabled={isSaving}
              >
                إلغاء
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={handleDeleteTransaction}
                disabled={isSaving}
              >
                {isSaving ? "جاري الحذف..." : "تأكيد الحذف"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Add Transaction Dialog */}
        <Dialog open={isAddModalOpen} onOpenChange={setIsAddModalOpen}>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle className="text-lg font-bold text-slate-900">
                إضافة معاملة جديدة
              </DialogTitle>
              <DialogDescription className="text-xs text-slate-500">
                تسجيل حركة مالية جديدة يدوياً في السجل
              </DialogDescription>
            </DialogHeader>

            {formError && (
              <div className="rounded-xl border border-red-200 bg-red-50 p-2.5 text-xs text-red-700">
                {formError}
              </div>
            )}

            <form onSubmit={handleSaveAdd} className="space-y-3 pt-2">
              <div className="space-y-1">
                <Label htmlFor="add-amount" className="text-xs font-semibold">
                  المبلغ ({business?.currency || "EGP"})
                </Label>
                <Input
                  id="add-amount"
                  type="number"
                  step="0.01"
                  required
                  placeholder="0.00"
                  value={formAmount}
                  onChange={(e) => setFormAmount(e.target.value)}
                  dir="ltr"
                  className="text-start font-semibold text-base"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <Label htmlFor="add-type" className="text-xs font-semibold">
                    النوع
                  </Label>
                  <Select
                    value={formType}
                    onValueChange={(val: any) => setFormType(val)}
                  >
                    <SelectTrigger id="add-type" className="text-xs">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="expense">مصروف</SelectItem>
                      <SelectItem value="income">إيراد</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-1">
                  <Label htmlFor="add-date" className="text-xs font-semibold">
                    التاريخ
                  </Label>
                  <Input
                    id="add-date"
                    type="date"
                    required
                    value={formDate}
                    onChange={(e) => setFormDate(e.target.value)}
                    className="text-xs"
                  />
                </div>
              </div>

              <div className="space-y-1">
                <Label htmlFor="add-cat" className="text-xs font-semibold">
                  التصنيف
                </Label>
                <Select
                  value={formCategoryId}
                  onValueChange={setFormCategoryId}
                >
                  <SelectTrigger id="add-cat" className="text-xs">
                    <SelectValue placeholder="اختر التصنيف" />
                  </SelectTrigger>
                  <SelectContent>
                    {categories.map((c) => (
                      <SelectItem key={c.id} value={c.id}>
                        {c.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1">
                <Label htmlFor="add-vendor" className="text-xs font-semibold">
                  اسم التاجر / العميل
                </Label>
                <Input
                  id="add-vendor"
                  value={formVendorName}
                  onChange={(e) => setFormVendorName(e.target.value)}
                  placeholder="مثال: سوبرماركت الأمل أو توريد بضاعة"
                  className="text-xs"
                />
              </div>

              <DialogFooter className="pt-3 gap-2">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => setIsAddModalOpen(false)}
                  disabled={isSaving}
                >
                  إلغاء
                </Button>
                <Button
                  type="submit"
                  size="sm"
                  className="bg-emerald-600 hover:bg-emerald-700 text-white"
                  disabled={isSaving}
                >
                  {isSaving ? "جاري الإضافة..." : "حفظ المعاملة"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    </DashboardLayout>
  )
}
