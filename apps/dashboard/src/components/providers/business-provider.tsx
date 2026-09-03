"use client"

import React, { createContext, useContext, useEffect, useState, useCallback } from "react"
import { useRouter, usePathname } from "next/navigation"
import { createClient } from "@/lib/supabase/client"
import type { Database } from "@/types/database.types"
import { Button } from "@/components/ui/button"
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
import { ShieldAlert, LogOut, Smartphone } from "lucide-react"

type Business = Database["public"]["Tables"]["businesses"]["Row"]

interface BusinessContextType {
  business: Business | null
  user: { id: string; email?: string; phone?: string } | null
  loading: boolean
  refreshBusiness: () => Promise<void>
  signOut: () => Promise<void>
}

const BusinessContext = createContext<BusinessContextType>({
  business: null,
  user: null,
  loading: true,
  refreshBusiness: async () => {},
  signOut: async () => {},
})

export function BusinessProvider({ children }: { children: React.ReactNode }) {
  const [business, setBusiness] = useState<Business | null>(null)
  const [user, setUser] = useState<{ id: string; email?: string; phone?: string } | null>(null)
  const [loading, setLoading] = useState(true)
  const [isUnlinked, setIsUnlinked] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const fetchUserAndBusiness = useCallback(async () => {
    try {
      setLoading(true)
      const {
        data: { session },
      } = await supabase.auth.getSession()

      let authUser: any = session?.user
      if (!authUser) {
        const { data: userData } = await supabase.auth.getUser()
        authUser = userData?.user
      }

      if (!authUser) {
        setUser(null)
        setBusiness(null)
        setIsUnlinked(false)
        setLoading(false)
        return
      }

      setUser({
        id: authUser.id,
        email: authUser.email,
        phone: authUser.phone,
      })

      // Query businesses for this owner
      const { data: businessData, error } = await supabase
        .from("businesses")
        .select("*")
        .eq("owner_id", authUser.id)
        .maybeSingle()

      if (error) {
        console.error("Error fetching business:", error)
      }

      if (!businessData) {
        // User is logged in but has no business profile
        // This means web access wasn't enabled from the mobile app
        setIsUnlinked(true)
        setBusiness(null)
      } else {
        setIsUnlinked(false)
        setBusiness(businessData)
      }
    } catch (err) {
      console.error("Error in fetchUserAndBusiness:", err)
    } finally {
      setLoading(false)
    }
  }, [supabase])

  useEffect(() => {
    fetchUserAndBusiness()

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session?.user) {
        fetchUserAndBusiness()
      } else {
        setUser(null)
        setBusiness(null)
        setIsUnlinked(false)
        setLoading(false)
      }
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [fetchUserAndBusiness, supabase])

  const refreshBusiness = async () => {
    await fetchUserAndBusiness()
  }

  const signOut = async () => {
    try {
      await supabase.auth.signOut()
      setUser(null)
      setBusiness(null)
      setIsUnlinked(false)
      window.location.href = "/login"
    } catch (err) {
      console.error("Error signing out:", err)
      window.location.href = "/login"
    }
  }

  const pathname = usePathname()
  const isAuthPage = pathname?.startsWith("/login") || pathname?.startsWith("/auth")

  if (isAuthPage) {
    return (
      <BusinessContext.Provider
        value={{
          business,
          user,
          loading,
          refreshBusiness: fetchUserAndBusiness,
          signOut,
        }}
      >
        {children}
      </BusinessContext.Provider>
    )
  }

  if (loading) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-slate-50">
        <div className="flex flex-col items-center gap-3">
          <div className="h-9 w-9 animate-spin rounded-full border-3 border-emerald-600 border-t-transparent" />
          <p className="text-sm font-medium text-slate-600">جاري تحميل بيانات الحساب...</p>
        </div>
      </div>
    )
  }

  if (isUnlinked) {
    return (
      <div className="flex min-h-screen w-full items-center justify-center bg-slate-100/70 p-4" dir="rtl">
        <Card className="max-w-md w-full border-slate-200/90 shadow-xl bg-white rounded-2xl">
          <CardHeader className="text-center pb-3">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-amber-50 text-amber-600 border border-amber-200/60 mb-2">
              <ShieldAlert className="h-7 w-7" />
            </div>
            <CardTitle className="text-xl font-bold text-slate-900">
              الحساب غير مرتبط بنشاط تجاري
            </CardTitle>
            <CardDescription className="text-sm text-slate-600 mt-2 leading-relaxed">
              هذا البريد الإلكتروني ({user?.email}) غير مرتبط بأي نشاط تجاري في حسابك على تطبيق الموبايل.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 pt-2">
            <div className="rounded-xl border border-slate-100 bg-slate-50 p-4 text-sm text-slate-700 space-y-2.5">
              <div className="flex items-center gap-2 font-medium text-slate-900">
                <Smartphone className="h-4 w-4 text-emerald-600" />
                <span>كيفية تفعيل الدخول من الويب:</span>
              </div>
              <ol className="list-decimal list-inside space-y-1.5 text-xs text-slate-600 leading-relaxed pr-2">
                <li>افتح تطبيق <strong>حسابلي</strong> على هاتفك المحمول.</li>
                <li>توجه إلى <strong>الإعدادات</strong> ➔ <strong>تفعيل الدخول عبر الويب</strong>.</li>
                <li>أدخل بريدك الإلكتروني لتأكيد الربط.</li>
                <li>بعد التأكيد، أعد تسجيل الدخول هنا على لوحة التحكم.</li>
              </ol>
            </div>

            <Button
              variant="outline"
              className="w-full border-slate-300 hover:bg-slate-100 text-slate-800"
              onClick={signOut}
            >
              <LogOut className="h-4 w-4 ml-2" />
              تسجيل الخروج والعودة
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <BusinessContext.Provider
      value={{
        business,
        user,
        loading,
        refreshBusiness: fetchUserAndBusiness,
        signOut,
      }}
    >
      {children}
    </BusinessContext.Provider>
  )
}

export function useBusiness() {
  const context = useContext(BusinessContext)
  if (!context) {
    throw new Error("useBusiness must be used within a BusinessProvider")
  }
  return context
}
