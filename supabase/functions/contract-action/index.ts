import { createClient } from 'npm:@supabase/supabase-js@2.111.0'

type Payload = {
  action?: 'accept'
  contract_version_id?: string
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
  if (userData.user.is_anonymous) return json({ error: 'verified_account_required' }, 403)

  let payload: Payload
  try {
    payload = await req.json()
  } catch {
    return json({ error: 'invalid_json' }, 400)
  }

  if (payload.action !== 'accept') return json({ error: 'invalid_action' }, 400)
  if (!payload.contract_version_id) return json({ error: 'contract_version_id_required' }, 400)

  try {
    const { data, error } = await admin.rpc('evento_accept_contract_v1', {
      p_user_id: userData.user.id,
      p_contract_version_id: payload.contract_version_id,
    })
    if (error) throw error
    return json({ ok: true, contract: data })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    if (message.includes('verified_account_required')) return json({ error: 'verified_account_required' }, 403)
    if (message.includes('forbidden')) return json({ error: 'forbidden' }, 403)
    if (message.includes('contract_not_found')) return json({ error: 'not_found' }, 404)
    if (message.includes('contract_expired')) return json({ error: 'contract_expired' }, 409)
    if (message.includes('legal_review_required')) return json({ error: 'legal_review_required' }, 409)
    if (message.includes('accepted_quote_required')) return json({ error: 'accepted_quote_required' }, 409)
    if (message.includes('contract_not_acceptable')) return json({ error: 'invalid_transition' }, 409)
    console.error('contract action failed')
    return json({ error: 'contract_action_failed' }, 500)
  }
})
