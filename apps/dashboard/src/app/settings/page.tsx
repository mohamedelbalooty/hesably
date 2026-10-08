"use client"

import React, { useState } from "react"
import { DashboardLayout } from "@/components/layout/dashboard-layout"
import { useBusiness } from "@/components/providers/business-provider"
import { createClient } from "@/lib/supabase/client"
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card"
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
import {
  Building2,
  Mail,
  ShieldCheck,
  LogOut,
  Save,
  CheckCircle2,
  AlertCircle,
  Smartphone,
} from "lucide-react"

export default function SettingsPage() {
  const { business, user, refreshBusiness, signOut } = useBusiness()

  // Business form state
  const [name, setName] = useState(business?.name || "")
  const [type, setType] = useState(business?.type || "retail")
  const [currency, setCurrency] = useState(business?.currency || "EGP")
  const [isSaving, setIsSaving] = useState(false)
  const [saveSuccess, setSaveSuccess] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  // Save Business Profile
  const handleSaveBusiness = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!business?.id) return

    const trimmedName = name.trim()
    if (!trimmedName) {
      setSaveError("يرجى إدخال اسم النشاط التجاري")
      return
    }

    try {
      setIsSaving(true)
      setSaveError(null)
      setSaveSuccess(false)
      const supabase = createClient()

      const { error } = await (supabase as any)
        .from("businesses")
        .update({
          name: trimmedName,
          type,
          currency,
        })
        .eq("id", business.id)

      if (error) {
        setSaveError(error.message || "فشل تحديث بيانات النشاط")
        return
      }

      await refreshBusiness()
      setSaveSuccess(true)
      setTimeout(() => setSaveSuccess(false), 3000)
    } catch (err: any) {
      setSaveError(err?.message || "حدث خطأ غير متوقع")
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <DashboardLayout>
      <div className="max-w-4xl space-y-6">
        {/* Header bar */}
        <div>
          <h2 className="text-xl font-black text-slate-900 tracking-tight">إعدادات الحساب والنشاط</h2>
          <p className="text-xs text-slate-500 mt-0.5">
            إدارة بيانات النشاط التجاري، حالة الدخول عبر الويب، وتسجيل الخروج
          </p>
        </div>

        {/* 1. Business Profile Card */}
        <Card className="rounded-2xl border-slate-200/80 shadow-xs">
          <CardHeader>
            <div className="flex items-center gap-2">
              <Building2 className="h-5 w-5 text-emerald-600" />
              <CardTitle className="text-base font-bold text-slate-900">
                الملف التجاري
              </CardTitle>
            </div>
            <CardDescription className="text-xs text-slate-500">
              تعديل بيانات النشاط التي تظهر في التقارير والفواتير (تتزامن مع تطبيق الموبايل)
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSaveBusiness} className="space-y-4">
              {saveSuccess && (
                <div className="flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-xs text-emerald-800">
                  <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                  <span>تم حفظ وتحديث بيانات النشاط التجاري بنجاح!</span>
                </div>
              )}

              {saveError && (
                <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-xs text-red-700">
                  <AlertCircle className="h-4 w-4 shrink-0" />
                  <span>{saveError}</span>
                </div>
              )}

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <Label htmlFor="biz-name" className="text-xs font-semibold text-slate-700">
                    اسم النشاط التجاري
                  </Label>
                  <Input
                    id="biz-name"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="مثال: بقالة التوفيق"
                    className="text-xs"
                  />
                </div>

                <div className="space-y-1.5">
                  <Label htmlFor="biz-type" className="text-xs font-semibold text-slate-700">
                    نوع النشاط
                  </Label>
                  <Select value={type} onValueChange={setType}>
                    <SelectTrigger id="biz-type" className="text-xs">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="retail">تجارة تجزئة / محل</SelectItem>
                      <SelectItem value="restaurant">مطعم / مقهى</SelectItem>
                      <SelectItem value="pharmacy">صيدلية</SelectItem>
                      <SelectItem value="service">خدمات / ورشة</SelectItem>
                      <SelectItem value="other">نشاط آخر</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-1.5">
                  <Label htmlFor="biz-currency" className="text-xs font-semibold text-slate-700">
                    العملة الأساسية
                  </Label>
                  <Select value={currency} onValueChange={setCurrency}>
                    <SelectTrigger id="biz-currency" className="text-xs">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="EGP">جنيه مصري (EGP)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="flex justify-end pt-2">
                <Button
                  type="submit"
                  disabled={isSaving}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs gap-1.5 rounded-xl shadow-xs"
                >
                  <Save className="h-3.5 w-3.5" />
                  <span>{isSaving ? "جاري الحفظ..." : "حفظ التعديلات"}</span>
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>

        {/* 2. Web Access Status Card */}
        <Card className="rounded-2xl border-slate-200/80 shadow-xs">
          <CardHeader>
            <div className="flex items-center gap-2">
              <Mail className="h-5 w-5 text-emerald-600" />
              <CardTitle className="text-base font-bold text-slate-900">
                حالة الدخول عبر الويب (Web Access)
              </CardTitle>
            </div>
            <CardDescription className="text-xs text-slate-500">
              البريد الإلكتروني المرتبط بحسابك لتسجيل الدخول السريع
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 rounded-xl border border-slate-100 bg-slate-50/70">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-100/70 text-emerald-700">
                  <ShieldCheck className="h-5 w-5" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-xs text-slate-900">
                      {user?.email || "غير محدد"}
                    </span>
                    <Badge variant="secondary" className="bg-emerald-50 text-emerald-700 text-[10px]">
                      مرتبط ونشط
                    </Badge>
                  </div>
                  <p className="text-[11px] text-slate-500 mt-0.5">
                    هذا البريد مرتبط بحسابك التجاري على الهاتف لتسجيل الدخول بالرابط السحري
                  </p>
                </div>
              </div>
            </div>

            <div className="rounded-xl border border-amber-200/60 bg-amber-50/50 p-3.5 text-xs text-amber-800 space-y-1 leading-relaxed">
              <div className="flex items-center gap-1.5 font-bold">
                <Smartphone className="h-3.5 w-3.5 text-amber-600" />
                <span>إدارة الربط أو إلغاء التفعيل:</span>
              </div>
              <p className="text-[11px] text-amber-700/90">
                لإلغاء ربط البريد الإلكتروني أو ربط بريد آخر، يمكنك إجراء ذلك بأمان من خلال تطبيق حسابلي على الموبايل من صفحة الإعدادات.
              </p>
            </div>
          </CardContent>
        </Card>

        {/* 3. Account Actions / Logout Card */}
        <Card className="rounded-2xl border-red-100 shadow-xs bg-red-50/20">
          <CardHeader>
            <CardTitle className="text-base font-bold text-slate-900">
              تسجيل الخروج
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">
              إنهاء الجلسة الحالية على متصفح الويب
            </CardDescription>
          </CardHeader>
          <CardFooter className="pt-0">
            <Button
              variant="destructive"
              size="sm"
              onClick={signOut}
              className="text-xs gap-1.5 rounded-xl"
            >
              <LogOut className="h-3.5 w-3.5" />
              <span>تسجيل الخروج من لوحة التحكم</span>
            </Button>
          </CardFooter>
        </Card>
      </div>
    </DashboardLayout>
  )
}
