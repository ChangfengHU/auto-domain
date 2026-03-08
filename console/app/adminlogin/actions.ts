'use server'

import { createClient } from '@/utils/supabase/server'
import { redirect } from 'next/navigation'

export async function adminLogin(formData: FormData) {
    const email = formData.get('email') as string
    const password = formData.get('password') as string

    if (!email || !password) {
        redirect('/adminlogin?error=Email and password are required')
    }

    const supabase = createClient()
    const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
    })

    if (error) {
        console.error('Admin login error:', error.message)
        redirect(`/adminlogin?error=${encodeURIComponent(error.message)}`)
    }

    redirect('/dashboard')
}
