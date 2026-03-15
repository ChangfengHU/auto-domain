import { NextRequest, NextResponse } from 'next/server'
import { normalizeText, parseBody, requireAdmin, sbAdmin } from '../../_lib'

async function ensureTunnel(tunnelId: string) {
    const res = await sbAdmin(
        `tunnel_instances?id=eq.${encodeURIComponent(tunnelId)}&select=id,name,status,owner_id,project_key,client_ip,os_type&limit=1`,
    )
    const rows = await res.json()
    if (!res.ok || !Array.isArray(rows) || rows.length === 0) {
        return { error: NextResponse.json({ error: 'Tunnel not found' }, { status: 404 }) }
    }
    return { tunnel: rows[0] }
}

export async function PATCH(
    req: NextRequest,
    { params }: { params: { id: string } }
) {
    const admin = await requireAdmin()
    if (admin.error) {
        return admin.error
    }

    const tunnelCheck = await ensureTunnel(params.id)
    if ('error' in tunnelCheck) {
        return tunnelCheck.error
    }

    const body = await parseBody<{
        name?: string
        owner_id?: string
        project_key?: string
        client_ip?: string
        os_type?: string
        status?: string
    }>(req)
    const patch: Record<string, unknown> = {}

    if (body.name !== undefined) {
        const name = normalizeText(body.name)
        if (!name) {
            return NextResponse.json({ error: '名称不能为空' }, { status: 400 })
        }
        patch.name = name
    }
    if (body.owner_id !== undefined) patch.owner_id = normalizeText(body.owner_id) || null
    if (body.project_key !== undefined) patch.project_key = normalizeText(body.project_key) || null
    if (body.client_ip !== undefined) patch.client_ip = normalizeText(body.client_ip) || null
    if (body.os_type !== undefined) patch.os_type = normalizeText(body.os_type) || null
    if (body.status !== undefined) {
        const status = normalizeText(body.status)
        if (status !== 'online' && status !== 'offline') {
            return NextResponse.json({ error: 'status must be online or offline' }, { status: 400 })
        }
        patch.status = status
    }

    if (Object.keys(patch).length === 0) {
        return NextResponse.json({ error: 'Nothing to update' }, { status: 400 })
    }

    const res = await sbAdmin(
        `tunnel_instances?id=eq.${encodeURIComponent(params.id)}`,
        {
            method: 'PATCH',
            headers: { Prefer: 'return=representation' },
            body: JSON.stringify(patch),
        },
    )
    const rows = await res.json()
    if (!res.ok) {
        return NextResponse.json({ error: 'Update failed', detail: rows }, { status: 500 })
    }

    return NextResponse.json({ tunnel: Array.isArray(rows) ? rows[0] : rows })
}

export async function DELETE(
    _req: NextRequest,
    { params }: { params: { id: string } }
) {
    const admin = await requireAdmin()
    if (admin.error) {
        return admin.error
    }

    const tunnelCheck = await ensureTunnel(params.id)
    if ('error' in tunnelCheck) {
        return tunnelCheck.error
    }

    const res = await sbAdmin(
        `tunnel_instances?id=eq.${encodeURIComponent(params.id)}`,
        {
            method: 'DELETE',
            headers: { Prefer: 'return=representation' },
        },
    )
    const rows = await res.json().catch(() => null)
    if (!res.ok) {
        return NextResponse.json({ error: 'Delete failed', detail: rows }, { status: 500 })
    }

    return NextResponse.json({ deleted: Array.isArray(rows) ? rows.length : 1, tunnel_id: params.id })
}
