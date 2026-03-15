import { NextRequest, NextResponse } from 'next/server'
import { normalizeText, parseBody, parseIds, requireAdmin, sbAdmin } from '../_lib'

export async function POST(req: NextRequest) {
    const admin = await requireAdmin()
    if (admin.error) {
        return admin.error
    }

    const body = await parseBody<{
        name?: string
        token_hash?: string
        owner_id?: string
        project_key?: string
        client_ip?: string
        os_type?: string
        status?: string
    }>(req)

    const name = normalizeText(body.name)
    const tokenHash = normalizeText(body.token_hash)
    if (!name) {
        return NextResponse.json({ error: '名称不能为空' }, { status: 400 })
    }
    if (!tokenHash) {
        return NextResponse.json({ error: 'token_hash 不能为空' }, { status: 400 })
    }

    const status = body.status === undefined ? 'offline' : normalizeText(body.status)
    if (status !== 'online' && status !== 'offline') {
        return NextResponse.json({ error: 'status must be online or offline' }, { status: 400 })
    }

    const res = await sbAdmin('tunnel_instances', {
        method: 'POST',
        headers: { Prefer: 'return=representation' },
        body: JSON.stringify({
            name,
            token_hash: tokenHash,
            owner_id: normalizeText(body.owner_id) || null,
            project_key: normalizeText(body.project_key) || null,
            client_ip: normalizeText(body.client_ip) || null,
            os_type: normalizeText(body.os_type) || null,
            status,
        }),
    })
    const rows = await res.json()
    if (!res.ok) {
        return NextResponse.json({ error: 'Create failed', detail: rows }, { status: 500 })
    }

    return NextResponse.json({ tunnel: Array.isArray(rows) ? rows[0] : rows }, { status: 201 })
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
        `tunnel_instances?id=in.(${encodeURIComponent(encodedIds)})`,
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
