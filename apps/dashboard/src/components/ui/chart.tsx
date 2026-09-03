"use client"

import React from "react"
import {
  ResponsiveContainer,
  BarChart as RechartsBarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  PieChart as RechartsPieChart,
  Pie,
  Cell,
  CartesianGrid,
} from "recharts"
import { formatCurrency } from "@/lib/utils"

interface CategoryData {
  name: string
  amount: number
  color?: string
}

const DEFAULT_COLORS = [
  "#10b981", // emerald-500
  "#3b82f6", // blue-500
  "#f59e0b", // amber-500
  "#ec4899", // pink-500
  "#8b5cf6", // violet-500
  "#06b6d4", // cyan-500
  "#f97316", // orange-500
  "#64748b", // slate-500
]

export function CategoryBarChart({
  data,
  currency = "EGP",
  height = 300,
}: {
  data: CategoryData[]
  currency?: string
  height?: number
}) {
  if (!data || data.length === 0) {
    return (
      <div
        style={{ height }}
        className="flex items-center justify-center text-sm text-slate-400 border border-dashed rounded-xl"
      >
        لا توجد بيانات متاحة
      </div>
    )
  }

  return (
    <div style={{ width: "100%", height }}>
      <ResponsiveContainer width="100%" height="100%">
        <RechartsBarChart
          data={data}
          margin={{ top: 10, right: 10, left: 10, bottom: 25 }}
        >
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
          <XAxis
            dataKey="name"
            tickLine={false}
            axisLine={false}
            tick={{ fill: "#64748b", fontSize: 12 }}
            interval={0}
            angle={-20}
            textAnchor="end"
          />
          <YAxis
            tickLine={false}
            axisLine={false}
            tick={{ fill: "#64748b", fontSize: 12 }}
            tickFormatter={(val) => `${val}`}
          />
          <Tooltip
            content={({ active, payload }) => {
              if (active && payload && payload.length) {
                const item = payload[0].payload as CategoryData
                return (
                  <div className="rounded-xl border border-slate-200 bg-white p-3 shadow-lg text-end">
                    <p className="font-semibold text-slate-800 text-sm">{item.name}</p>
                    <p className="text-emerald-600 font-bold text-base mt-1">
                      {formatCurrency(item.amount, currency)}
                    </p>
                  </div>
                )
              }
              return null
            }}
          />
          <Bar
            dataKey="amount"
            radius={[6, 6, 0, 0]}
            fill="#10b981"
          >
            {data.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={entry.color || DEFAULT_COLORS[index % DEFAULT_COLORS.length]}
              />
            ))}
          </Bar>
        </RechartsBarChart>
      </ResponsiveContainer>
    </div>
  )
}

export function CategoryDonutChart({
  data,
  currency = "EGP",
  height = 260,
}: {
  data: CategoryData[]
  currency?: string
  height?: number
}) {
  if (!data || data.length === 0) {
    return (
      <div
        style={{ height }}
        className="flex items-center justify-center text-sm text-slate-400 border border-dashed rounded-xl"
      >
        لا توجد بيانات متاحة
      </div>
    )
  }

  return (
    <div style={{ width: "100%", height }} className="relative flex items-center justify-center">
      <ResponsiveContainer width="100%" height="100%">
        <RechartsPieChart>
          <Tooltip
            content={({ active, payload }) => {
              if (active && payload && payload.length) {
                const item = payload[0].payload as CategoryData
                return (
                  <div className="rounded-xl border border-slate-200 bg-white p-3 shadow-lg text-end">
                    <p className="font-semibold text-slate-800 text-sm">{item.name}</p>
                    <p className="text-slate-900 font-bold text-base mt-1">
                      {formatCurrency(item.amount, currency)}
                    </p>
                  </div>
                )
              }
              return null
            }}
          />
          <Pie
            data={data}
            innerRadius={60}
            outerRadius={85}
            paddingAngle={4}
            dataKey="amount"
          >
            {data.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={entry.color || DEFAULT_COLORS[index % DEFAULT_COLORS.length]}
              />
            ))}
          </Pie>
        </RechartsPieChart>
      </ResponsiveContainer>
    </div>
  )
}
