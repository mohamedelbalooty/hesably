"use client"

import React, { useEffect, useState } from "react"
import { DashboardLayout } from "@/components/layout/dashboard-layout"
import { useBusiness } from "@/components/providers/business-provider"
import { createClient } from "@/lib/supabase/client"
import type { Database } from "@/types/database.types"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
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
import { Plus, Edit2, Trash2, Tags, Eye, EyeOff, ShieldCheck, AlertCircle } from "lucide-react"

type Category = Database["public"]["Tables"]["categories"]["Row"] & {
  transaction_count?: number
}

export default function CategoriesPage() {
  const { business } = useBusiness()
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)

  // Add category state
  const [isAddOpen, setIsAddOpen] = useState(false)
  const [addName, setAddName] = useState("")

  // Edit category state
  const [editingCategory, setEditingCategory] = useState<Category | null>(null)
  const [editName, setEditName] = useState("")

  // Delete category state
  const [deletingCategory, setDeletingCategory] = useState<Category | null>(null)

  const [actionError, setActionError] = useState<string | null>(null)
  const [isSaving, setIsSaving] = useState(false)

  // Load categories and their transaction usage counts
  const loadCategories = async () => {
    if (!business?.id) return

    try {
      setLoading(true)
      const supabase = createClient()

      // Fetch all categories for this business
      const { data: cats, error } = await (supabase as any)
        .from("categories")
        .select("*")
        .eq("business_id", business.id)
        .order("is_default", { ascending: false })
        .order("name", { ascending: true })

      if (error) {
        console.error("Error loading categories:", error)
        return
      }

      // Fetch transaction counts for each category
      const { data: txCounts } = await (supabase as any)
        .from("transactions")
        .select("category_id")
        .eq("business_id", business.id)

      const countMap: Record<string, number> = {}
      ;(txCounts as any[])?.forEach((tx: any) => {
        if (tx && tx.category_id) {
          countMap[tx.category_id] = (countMap[tx.category_id] || 0) + 1
        }
      })

      const enriched = ((cats as Category[]) || []).map((c: Category) => ({
        ...c,
        transaction_count: countMap[c.id] || 0,
      }))

      setCategories(enriched)
    } catch (err) {
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadCategories()
  }, [business?.id])

  // Add Category
  const handleAddCategory = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!business?.id) return

    const trimmed = addName.trim()
    if (!trimmed) {
      setActionError("يرجى إدخال اسم التصنيف")
      return
    }

    try {
      setIsSaving(true)
      setActionError(null)
      const supabase = createClient()

      const { error } = await (supabase as any).from("categories").insert({
        business_id: business.id,
        name: trimmed,
        is_default: false,
        is_hidden: false,
      })

      if (error) {
        if (error.code === "23505") {
          setActionError("يوجد تصنيف بهذا الاسم مسبقاً")
        } else {
          setActionError(error.message || "فشل إضافة التصنيف")
        }
        return
      }

      setAddName("")
      setIsAddOpen(false)
      await loadCategories()
    } catch (err: any) {
      setActionError(err?.message || "حدث خطأ غير متوقع")
    } finally {
      setIsSaving(false)
    }
  }

  // Edit Category
  const handleEditCategory = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editingCategory || !business?.id) return

    const trimmed = editName.trim()
    if (!trimmed) {
      setActionError("يرجى إدخال اسم التصنيف")
      return
    }

    try {
      setIsSaving(true)
      setActionError(null)
      const supabase = createClient()

      const { error } = await (supabase as any)
        .from("categories")
        .update({ name: trimmed })
        .eq("id", editingCategory.id)
        .eq("business_id", business.id)

      if (error) {
        if (error.code === "23505") {
          setActionError("يوجد تصنيف بهذا الاسم مسبقاً")
        } else {
          setActionError(error.message || "فشل تعديل التصنيف")
        }
        return
      }

      setEditingCategory(null)
      await loadCategories()
    } catch (err: any) {
      setActionError(err?.message || "حدث خطأ غير متوقع")
    } finally {
      setIsSaving(false)
    }
  }

  // Toggle Hide / Show Default Category
  const handleToggleHide = async (category: Category) => {
    if (!business?.id) return

    try {
      const supabase = createClient()
      const { error } = await (supabase as any)
        .from("categories")
        .update({ is_hidden: !category.is_hidden })
        .eq("id", category.id)
        .eq("business_id", business.id)

      if (error) {
        console.error("Hide error:", error)
        return
      }

      await loadCategories()
    } catch (err) {
      console.error(err)
    }
  }

  // Delete Custom Category
  const handleDeleteCategory = async () => {
    if (!deletingCategory || !business?.id) return

    if (deletingCategory.is_default) {
      setActionError("لا يمكن حذف التصنيفات الأساسية للنظام")
      return
    }

    if ((deletingCategory.transaction_count || 0) > 0) {
      setActionError(
        "لا يمكن حذف هذا التصنيف لأنه مستخدم في معاملات حالية. يرجى نقل المعاملات أولاً."
      )
      return
    }

    try {
      setIsSaving(true)
      setActionError(null)
      const supabase = createClient()

      const { error } = await (supabase as any)
        .from("categories")
        .delete()
        .eq("id", deletingCategory.id)
        .eq("business_id", business.id)

      if (error) {
        setActionError(error.message || "فشل حذف التصنيف")
        return
      }

      setDeletingCategory(null)
      await loadCategories()
    } catch (err: any) {
      setActionError(err?.message || "حدث خطأ غير متوقع")
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
            <h2 className="text-xl font-black text-slate-900 tracking-tight">إدارة التصنيفات</h2>
            <p className="text-xs text-slate-500 mt-0.5">
              تنظيم وتصنيف بنود المصروفات والإيرادات للنشاط التجاري
            </p>
          </div>
          <Button
            onClick={() => {
              setAddName("")
              setActionError(null)
              setIsAddOpen(true)
            }}
            className="bg-emerald-600 hover:bg-emerald-700 text-white gap-2 shadow-xs rounded-xl"
          >
            <Plus className="h-4 w-4" />
            <span>إضافة تصنيف جديد</span>
          </Button>
        </div>

        {/* Categories Table */}
        <Card className="rounded-2xl border-slate-200/80 shadow-xs overflow-hidden">
          <CardContent className="p-0">
            {loading ? (
              <div className="flex flex-col items-center justify-center py-16">
                <div className="h-8 w-8 animate-spin rounded-full border-3 border-emerald-600 border-t-transparent mb-2" />
                <p className="text-xs text-slate-500">جاري تحميل التصنيفات...</p>
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>اسم التصنيف</TableHead>
                    <TableHead>النوع</TableHead>
                    <TableHead>عدد المعاملات المرتبطة</TableHead>
                    <TableHead>الحالة</TableHead>
                    <TableHead className="text-end">الإجراءات</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {categories.map((cat) => (
                    <TableRow key={cat.id}>
                      <TableCell className="font-bold text-xs text-slate-900">
                        {cat.name}
                      </TableCell>
                      <TableCell>
                        {cat.is_default ? (
                          <Badge variant="secondary" className="text-[11px] gap-1 bg-slate-100 text-slate-700 border-slate-200">
                            <ShieldCheck className="h-3 w-3 text-slate-500" />
                            <span>أساسي (نظام)</span>
                          </Badge>
                        ) : (
                          <Badge variant="outline" className="text-[11px] gap-1 text-emerald-700 border-emerald-200 bg-emerald-50/50">
                            <Tags className="h-3 w-3" />
                            <span>مخصص</span>
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-xs text-slate-600 font-semibold">
                        {cat.transaction_count || 0} معاملة
                      </TableCell>
                      <TableCell>
                        {cat.is_hidden ? (
                          <Badge variant="outline" className="text-[10px] text-amber-700 border-amber-200 bg-amber-50">
                            مخفي من القوائم
                          </Badge>
                        ) : (
                          <Badge variant="outline" className="text-[10px] text-emerald-700 border-emerald-200 bg-emerald-50">
                            نشط
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-end">
                        <div className="flex items-center justify-end gap-1">
                          {cat.is_default ? (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-8 text-xs text-slate-600 hover:text-slate-900 gap-1"
                              onClick={() => handleToggleHide(cat)}
                            >
                              {cat.is_hidden ? (
                                <>
                                  <Eye className="h-3.5 w-3.5 text-emerald-600" />
                                  <span>إظهار</span>
                                </>
                              ) : (
                                <>
                                  <EyeOff className="h-3.5 w-3.5 text-slate-400" />
                                  <span>إخفاء</span>
                                </>
                              )}
                            </Button>
                          ) : (
                            <>
                              <Button
                                variant="ghost"
                                size="sm"
                                className="h-8 px-2 text-xs text-slate-600 hover:text-emerald-700"
                                onClick={() => {
                                  setEditingCategory(cat)
                                  setEditName(cat.name)
                                  setActionError(null)
                                }}
                              >
                                <Edit2 className="h-3.5 w-3.5 ml-1" />
                                <span>تعديل</span>
                              </Button>
                              <Button
                                variant="ghost"
                                size="sm"
                                className="h-8 px-2 text-xs text-red-600 hover:text-red-700 hover:bg-red-50"
                                onClick={() => {
                                  setDeletingCategory(cat)
                                  setActionError(null)
                                }}
                              >
                                <Trash2 className="h-3.5 w-3.5 ml-1" />
                                <span>حذف</span>
                              </Button>
                            </>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        {/* Add Category Dialog */}
        <Dialog open={isAddOpen} onOpenChange={setIsAddOpen}>
          <DialogContent className="max-w-sm">
            <DialogHeader>
              <DialogTitle className="text-base font-bold text-slate-900">
                إضافة تصنيف مخصص جديد
              </DialogTitle>
              <DialogDescription className="text-xs text-slate-500">
                أدخل اسم التصنيف الجديد لتسهيل تتبع نفقاتك
              </DialogDescription>
            </DialogHeader>

            {actionError && (
              <div className="rounded-xl border border-red-200 bg-red-50 p-2.5 text-xs text-red-700">
                {actionError}
              </div>
            )}

            <form onSubmit={handleAddCategory} className="space-y-4 pt-1">
              <div className="space-y-1.5">
                <Label htmlFor="cat-name" className="text-xs font-semibold">
                  اسم التصنيف
                </Label>
                <Input
                  id="cat-name"
                  required
                  placeholder="مثال: شحن وبضائع، صيانة أجهزة"
                  value={addName}
                  onChange={(e) => setAddName(e.target.value)}
                  className="text-xs"
                />
              </div>

              <DialogFooter className="pt-2 gap-2">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => setIsAddOpen(false)}
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
                  {isSaving ? "جاري الإضافة..." : "حفظ التصنيف"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>

        {/* Edit Category Dialog */}
        <Dialog
          open={!!editingCategory}
          onOpenChange={(open) => !open && setEditingCategory(null)}
        >
          <DialogContent className="max-w-sm">
            <DialogHeader>
              <DialogTitle className="text-base font-bold text-slate-900">
                تعديل اسم التصنيف
              </DialogTitle>
              <DialogDescription className="text-xs text-slate-500">
                تحديث مسمى التصنيف المخصص
              </DialogDescription>
            </DialogHeader>

            {actionError && (
              <div className="rounded-xl border border-red-200 bg-red-50 p-2.5 text-xs text-red-700">
                {actionError}
              </div>
            )}

            <form onSubmit={handleEditCategory} className="space-y-4 pt-1">
              <div className="space-y-1.5">
                <Label htmlFor="edit-cat-name" className="text-xs font-semibold">
                  اسم التصنيف
                </Label>
                <Input
                  id="edit-cat-name"
                  required
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="text-xs"
                />
              </div>

              <DialogFooter className="pt-2 gap-2">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => setEditingCategory(null)}
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
                  {isSaving ? "جاري الحفظ..." : "حفظ التعديل"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>

        {/* Delete Confirmation Dialog */}
        <Dialog
          open={!!deletingCategory}
          onOpenChange={(open) => !open && setDeletingCategory(null)}
        >
          <DialogContent className="max-w-sm">
            <DialogHeader>
              <DialogTitle className="text-base font-bold text-slate-900">
                حذف التصنيف
              </DialogTitle>
              <DialogDescription className="text-xs text-slate-500">
                هل أنت متأكد من رغبتك في حذف التصنيف &ldquo;{deletingCategory?.name}&rdquo;؟
              </DialogDescription>
            </DialogHeader>

            {actionError && (
              <div className="flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 p-2.5 text-xs text-red-700">
                <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{actionError}</span>
              </div>
            )}

            <DialogFooter className="pt-2 gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setDeletingCategory(null)}
                disabled={isSaving}
              >
                إلغاء
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={handleDeleteCategory}
                disabled={isSaving}
              >
                {isSaving ? "جاري الحذف..." : "تأكيد الحذف"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </DashboardLayout>
  )
}
