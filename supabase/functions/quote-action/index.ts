import { createClient } from 'npm:@supabase/supabase-js@2.111.0'

type Payload = {
  action?: 'create_draft' | 'send' | 'accept'
  request_id?: string
  quote_id?: string
  subtotal_aed?: string | number
  discount_aed?: string | number
  tax_aed?: string | number
  pricing_breakdown?: unknown
  valid_until?: string | null
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json; charset=utf-8' },
  })

const getAdminKey = () => {
  const secretKeysJson = Deno.env.get('SUPABASE_SECRET_KEYS')
  if (secretKeysJson) {
    try {
      const keys = JSON.parse(secretKeysJson) as Record<string, string>
      if (keys.default) return keys.default
    } catch {
      // Fall through to hosted service-role secret.
    }
  }
  return Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
}

const amount = (value: string | number | undefined, fallback = '0') => {
  const text = value === undefined ? fallback : String(value).trim()
  if (!/^\d+(\.\d{1,2})?$/.test(text)) throw new Error('invalid_amount')
  return text
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  const authorization = req.headers.get('authorization') ?? ''
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : ''
  if (!token) return json({ error: 'authentication_required' }, 401)

  const url = Deno.env.get('SUPABASE_URL')
  const adminKey = getAdminKey()
  if (!url || !adminKey) return json({ error: 'server_configuration_error' }, 500)

  const admin = createClient(url, adminKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  const { data: userData, error: userError } = await admin.auth.getUser(token)
  if (userError || !userData.user) return json({ error: 'invalid_session' }, 401)

  let payload: Payload
  try {
    payload = await req.json()
  } catch {
    return json({ error: 'invalid_json' }, 400)
  }

  if (!payload.action) return json({ error: 'action_required' }, 400)

  try {
    if (payload.action === 'create_draft') {
      if (!payload.request_id) return json({ error: 'request_id_required' }, 400)
      const subtotal = amount(payload.subtotal_aed)
      const discount = amount(payload.discount_aed, '0')
      const tax = amount(payload.tax_aed, '0')

      const { data, error } = await admin.rpc('evento_create_quote_draft_v1', {
        p_actor_user_id: userData.user.id,
        p_request_id: payload.request_id,
        p_subtotal_aed: subtotal,
        p_discount_aed: discount,
        p_tax_aed: tax,
        p_pricing_breakdown: payload.pricing_breakdown ?? [],
        p_valid_until: payload.valid_until ?? null,
      })
      if (error) throw error
      return json({ ok: true, quote: data })
    }

    if (!payload.quote_id) return json({ error: 'quote_id_required' }, 400)

    if (payload.action === 'send') {
      const { data, error } = await admin.rpc('evento_send_quote_v1', {
        p_actor_user_id: userData.user.id,
        p_quote_id: payload.quote_id,
      })
      if (error) throw error
      return json({ ok: true, quote: data })
    }

    if (payload.action === 'accept') {
      if (userData.user.is_anonymous) return json({ error: 'verified_account_required' }, 403)
      const { data, error } = await admin.rpc('evento_accept_quote_v1', {
        p_user_id: userData.user.id,
        p_quote_id: payload.quote_id,
      })
      if (error) throw error
      return json({ ok: true, quote: data })
    }

    return json({ error: 'invalid_action' }, 400)
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    if (message.includes('invalid_amount')) return json({ error: 'invalid_amount' }, 400)
    if (message.includes('staff_permission_required')) return json({ error: 'staff_permission_required' }, 403)
    if (message.includes('verified_account_required')) return json({ error: 'verified_account_required' }, 403)
    if (message.includes('forbidden')) return json({ error: 'forbidden' }, 403)
    if (message.includes('request_not_found') || message.includes('quote_not_found')) return json({ error: 'not_found' }, 404)
    if (message.includes('scope_not_approved') || message.includes('quote_not_sendable') || message.includes('quote_not_acceptable')) {
      return json({ error: 'invalid_transition' }, 409)
    }
    if (message.includes('quote_expired')) return json({ error: 'quote_expired' }, 409)
    console.error('quote action failed')
    return json({ error: 'quote_action_failed' }, 500)
  }
})
