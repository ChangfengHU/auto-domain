import { NextRequest, NextResponse } from 'next/server'
import { ensureRouteExists, ensureUniqueHostname, normalizeText, parseBody, requireAdmin, sbAdmin } from '../../_lib'

export async function PATCH(
    req: NextRequest,
    { params }: { params: { id: string } }
) {
    const admin = await requireAdmin()
    if (admin.error) {
        return admin.error
    }

    const routeCheck = await ensureRouteExists(params.id)
    if ('error' in routeCheck) {
        return routeCheck.error
    }

    const routeId = params.id
    const body = await parseBody<{
        hostname?: string
        target?: string
        is_enabled?: boolean
    }>(req)
    const patch: Record<string, unknown> = {}

    if (body.hostname !== undefined) {
        const hostname = normalizeText(body.hostname)
        if (!hostname) {
            return NextResponse.json({ error: '域名不能为空' }, { status: 400 })
        }
        const duplicate = await ensureUniqueHostname(hostname, routeId)
        if (duplicate) {
            return duplicate
        }
        patch.hostname = hostname
    }

    if (body.target !== undefined) {
        const target = normalizeText(body.target)
        if (!target) {
            return NextResponse.json({ error: '目标地址不能为空' }, { status: 400 })
        }
        patch.target = target
    }

    if (body.is_enabled !== undefined) {
        patch.is_enabled = Boolean(body.is_enabled)
    }

    if (Object.keys(patch).length === 0) {
        return NextResponse.json({ error: 'Nothing to update' }, { status: 400 })
    }

    const updateRes = await sbAdmin(
        `tunnel_routes?id=eq.${encodeURIComponent(routeId)}`,
        {
            method: 'PATCH',
            headers: { Prefer: 'return=representation' },
            body: JSON.stringify(patch),
        },
    )
    const updated = await updateRes.json()

    if (!updateRes.ok) {
        return NextResponse.json({ error: 'Update failed', detail: updated }, { status: 500 })
    }

    const route = Array.isArray(updated) ? updated[0] : updated
    return NextResponse.json({ route })
}

export async function DELETE(
    _req: NextRequest,
    { params }: { params: { id: string } }
) {
    const admin = await requireAdmin()
    if (admin.error) {
        return admin.error
    }

    const routeCheck = await ensureRouteExists(params.id)
    if ('error' in routeCheck) {
        return routeCheck.error
    }

    const res = await sbAdmin(
        `tunnel_routes?id=eq.${encodeURIComponent(params.id)}`,
        {
            method: 'DELETE',
            headers: { Prefer: 'return=representation' },
        },
    )
    const rows = await res.json().catch(() => null)
    if (!res.ok) {
        return NextResponse.json({ error: 'Delete failed', detail: rows }, { status: 500 })
    }

    return NextResponse.json({ deleted: Array.isArray(rows) ? rows.length : 1, route_id: params.id })
}
