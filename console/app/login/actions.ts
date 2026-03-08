'use server'

import { redirect } from 'next/navigation'

const CONTROL_API_BASE = process.env.CONTROL_API_BASE || 'http://127.0.0.1:18100'

export async function login(formData: FormData) {
    const tunnelId = formData.get('tunnel_id') as string

    if (!tunnelId) {
        redirect('/login?error=Tunnel ID is required')
    }

    try {
        // Verify tunnel exists by calling control API
        const response = await fetch(`${CONTROL_API_BASE}/api/tunnels/${tunnelId}`, {
            method: 'GET',
        })

        if (!response.ok) {
            redirect('/login?error=Invalid Tunnel ID or Tunnel not found')
        }

        // Store tunnel_id in session/cookie
        // For now, we'll redirect to portal dashboard with tunnel_id as param
        // The portal page will handle storage
        redirect(`/portal/dashboard?tunnel_id=${encodeURIComponent(tunnelId)}`)
    } catch (error) {
        console.error('Login error:', error)
        redirect('/login?error=Failed to verify Tunnel ID')
    }
}
