"use client"

import React, { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/client"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Mail, CheckCircle2, AlertCircle, Smartphone, ArrowRight } from "lucide-react"

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState("")
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const supabase = createClient()

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (session) {
        window.location.href = "/"
      }
    })
    return () => {
      subscription.unsubscribe()
    }
  }, [supabase])

  const handleSendMagicLink = async (e: React.FormEvent) => {
    e.preventDefault()
    setErrorMsg(null)

    if (!email || !email.includes("@")) {
      setErrorMsg("يرجى إدخال بريد إلكتروني صحيح")
      return
    }

    try {
      setLoading(true)
      const redirectUrl = `${window.location.origin}/auth/callback`

      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: {
          emailRedirectTo: redirectUrl,
          shouldCreateUser: false, // Prevents creating brand new orphaned users directly on dashboard
        },
      })

      if (error) {
        // If shouldCreateUser: false blocked it because user doesn't exist
        if (error.message.toLowerCase().includes("signups not allowed") || error.message.toLowerCase().includes("user not found")) {
          setErrorMsg("هذا البريد غير مسجل. يرجى تفعيل الدخول عبر الويب من تطبيق الموبايل أولاً.")
        } else {
          setErrorMsg(error.message || "حدث خطأ أثناء إرسال رابط الدخول")
        }
        return
      }

      setSuccess(true)
    } catch (err: any) {
      setErrorMsg(err?.message || "حدث خطأ غير متوقع")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-slate-100 via-emerald-50/20 to-slate-100 p-4" dir="rtl">
      <div className="w-full max-w-md space-y-6">
        {/* Brand Header */}
        <div className="text-center space-y-2">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-tr from-emerald-600 to-teal-500 text-white font-bold text-2xl shadow-md">
            ح
          </div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">حسابلي</h1>
          <p className="text-sm text-slate-500 font-medium">لوحة التحكم المالية عبر الويب</p>
        </div>

        <Card className="border-slate-200/90 shadow-xl bg-white rounded-2xl overflow-hidden">
          <CardHeader className="space-y-1.5 pb-4">
            <CardTitle className="text-xl font-bold text-slate-900 text-center">
              تسجيل الدخول
            </CardTitle>
            <CardDescription className="text-xs text-slate-500 text-center">
              أدخل البريد الإلكتروني المرتبط بحسابك لتلقي رابط الدخول السحري
            </CardDescription>
          </CardHeader>

          <CardContent className="space-y-4">
            {success ? (
              <div className="space-y-4 text-center py-4">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
                  <CheckCircle2 className="h-6 w-6" />
                </div>
                <div className="space-y-1.5">
                  <h3 className="font-bold text-slate-900 text-base">تم إرسال الرابط بنجاح!</h3>
                  <p className="text-xs text-slate-600 leading-relaxed px-2">
                    أرسلنا رابط تسجيل الدخول إلى <strong>{email}</strong>. انقر على الرابط في رسالتك للدخول مباشرة.
                  </p>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  className="mt-2 text-xs"
                  onClick={() => setSuccess(false)}
                >
                  <ArrowRight className="h-3.5 w-3.5 ml-1" />
                  إعادة المحاولة أو تغيير البريد
                </Button>
              </div>
            ) : (
              <form onSubmit={handleSendMagicLink} className="space-y-4">
                {errorMsg && (
                  <div className="flex items-start gap-2.5 rounded-xl border border-red-200 bg-red-50/80 p-3 text-xs text-red-700 leading-relaxed">
                    <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                    <span>{errorMsg}</span>
                  </div>
                )}

                <div className="space-y-2">
                  <Label htmlFor="email" className="text-xs font-semibold text-slate-700">
                    البريد الإلكتروني
                  </Label>
                  <div className="relative">
                    <Input
                      id="email"
                      type="email"
                      required
                      placeholder="name@example.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="pr-10 text-start"
                      dir="ltr"
                      disabled={loading}
                    />
                    <Mail className="absolute right-3 top-2.5 h-5 w-5 text-slate-400 pointer-events-none" />
                  </div>
                </div>

                <Button
                  type="submit"
                  disabled={loading}
                  className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-semibold h-11 shadow-sm rounded-xl text-sm"
                >
                  {loading ? (
                    <div className="flex items-center gap-2">
                      <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                      <span>جاري إرسال الرابط...</span>
                    </div>
                  ) : (
                    <span>إرسال رابط الدخول السحري</span>
                  )}
                </Button>
              </form>
            )}

            {/* Note regarding mobile-first account creation */}
            <div className="rounded-xl border border-slate-100 bg-slate-50/80 p-3 text-xs text-slate-600 space-y-1.5 mt-4">
              <div className="flex items-center gap-1.5 font-semibold text-slate-800">
                <Smartphone className="h-3.5 w-3.5 text-emerald-600" />
                <span>ملاحظة هامة</span>
              </div>
              <p className="text-[11px] leading-relaxed text-slate-500">
                إنشاء الحسابات متاح عبر تطبيق الهاتف فقط. إذا لم تقم بربط بريدك الإلكتروني بعد، افتح التطبيق ➔ الإعدادات ➔ تفعيل الدخول عبر الويب.
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
