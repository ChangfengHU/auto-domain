import { NextRequest, NextResponse } from 'next/server'
import { ensureTunnelExists, ensureUniqueHostname, normalizeText, parseBody, parseIds, requireAdmin, sbAdmin } from '../_lib'

export async function POST(req: NextRequest) {
    const admin = await requireAdmin()
    if (admin.error) {
        return admin.error
    }

    const body = await parseBody<{
        tunnel_id?: string
        hostname?: string
        target?: string
        is_enabled?: boolean
    }>(req)

    const tunnelId = normalizeText(body.tunnel_id)
    const hostname = normalizeText(body.hostname)
    const target = normalizeText(body.target)

    if (!tunnelId) {
        return NextResponse.json({ error: 'tunnel_id is required' }, { status: 400 })
    }
    if (!hostname) {
        return NextResponse.json({ error: '域名不能为空' }, { status: 400 })
    }
    if (!target) {
        return NextResponse.json({ error: '目标地址不能为空' }, { status: 400 })
    }

    const tunnelCheck = await ensureTunnelExists(tunnelId)
    if (tunnelCheck) {
        return tunnelCheck
    }

    const duplicate = await ensureUniqueHostname(hostname)
    if (duplicate) {
        return duplicate
    }

    const res = await sbAdmin('tunnel_routes', {
        method: 'POST',
        headers: { Prefer: 'return=representation' },
        body: JSON.stringify({
            tunnel_id: tunnelId,
            hostname,
            target,
            is_enabled: body.is_enabled === undefined ? true : Boolean(body.is_enabled),
        }),
    })
    const rows = await res.json()
    if (!res.ok) {
        return NextResponse.json({ error: 'Create failed', detail: rows }, { status: 500 })
    }

    return NextResponse.json({ route: Array.isArray(rows) ? rows[0] : rows }, { status: 201 })
}

export async function DELETE(req: NextRequest) {
    const admin = await requireAdmin()
    if (admin.error) {
        return admin.error
    }

    const body = await parseBody<{ ids?: string[] }>(req)
    const ids = parseIds(body.ids)
    if (ids.length === 0) {
        return NextResponse.json({ error: 'ids is required' }, { status: 400 })
    }

    const encodedIds = ids.map((id) => `"${id}"`).join(',')
    const res = await sbAdmin(
        `tunnel_routes?id=in.(${encodeURIComponent(encodedIds)})`,
        {
            method: 'DELETE',
            headers: { Prefer: 'return=representation' },
        },
    )
    const rows = await res.json().catch(() => [])
    if (!res.ok) {
        return NextResponse.json({ error: 'Bulk delete failed', detail: rows }, { status: 500 })
    }

    return NextResponse.json({
        deleted: Array.isArray(rows) ? rows.length : 0,
        ids,
    })
}
