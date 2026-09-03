export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      businesses: {
        Row: {
          id: string
          owner_id: string
          name: string
          type: string
          currency: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          owner_id: string
          name: string
          type: string
          currency?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          owner_id?: string
          name?: string
          type?: string
          currency?: string
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      categories: {
        Row: {
          id: string
          business_id: string
          name: string
          is_default: boolean
          is_hidden: boolean
          created_at: string
        }
        Insert: {
          id?: string
          business_id: string
          name: string
          is_default?: boolean
          is_hidden?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          business_id?: string
          name?: string
          is_default?: boolean
          is_hidden?: boolean
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "categories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          }
        ]
      }
      transactions: {
        Row: {
          id: string
          business_id: string
          type: "income" | "expense"
          amount: number
          date: string
          category_id: string
          vendor_customer_name: string | null
          receipt_image_path: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          business_id: string
          type: "income" | "expense"
          amount: number
          date: string
          category_id: string
          vendor_customer_name?: string | null
          receipt_image_path?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          business_id?: string
          type?: "income" | "expense"
          amount?: number
          date?: string
          category_id?: string
          vendor_customer_name?: string | null
          receipt_image_path?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "transactions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transactions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_financial_summary: {
        Args: {
          p_business_id: string
          p_start_date: string
          p_end_date: string
        }
        Returns: {
          total_income: number
          total_expense: number
          net: number
        }[]
      }
      get_category_breakdown: {
        Args: {
          p_business_id: string
          p_start_date: string
          p_end_date: string
          p_type: "income" | "expense"
        }
        Returns: {
          category_id: string
          category_name: string
          total_amount: number
        }[]
      }
      delete_user_account: {
        Args: Record<PropertyKey, never>
        Returns: void
      }
    }
    Enums: {
      transaction_type: "income" | "expense"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}
