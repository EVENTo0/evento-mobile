import { createClient } from 'npm:@supabase/supabase-js@2.111.0'

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: {'content-type':'application/json; charset=utf-8'},
})

const getAdminKey = () => {
  const secretKeysJson = Deno.env.get('SUPABASE_SECRET_KEYS')
  if (secretKeysJson) {
    try {
      const keys = JSON.parse(secretKeysJson) as Record<string,string>
      if (keys.default) return keys.default
    } catch {}
  }
  return Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
}

const isTestStripeKey = (value: string) =>
  value.startsWith('rk_test_') || value.startsWith('sk_test_')

const testOnlyProjectRefs = new Set(['zgyovnqjmaognsjyylvk'])
const projectRefFromUrl = (value: string) => {
  try { return new URL(value).hostname.split('.')[0] ?? '' } catch { return '' }
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return json({error:'method_not_allowed'},405)
  const authorization = req.headers.get('authorization') ?? ''
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : ''
  if (!token) return json({error:'authentication_required'},401)

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const adminKey = getAdminKey()
  const stripeKey = Deno.env.get('STRIPE_RESTRICTED_KEY') ?? Deno.env.get('STRIPE_SECRET_KEY') ?? ''
  const successUrl = Deno.env.get('EVENTO_CHECKOUT_SUCCESS_URL') ?? ''
  const cancelUrl = Deno.env.get('EVENTO_CHECKOUT_CANCEL_URL') ?? ''
  const reconciliationMode = testOnlyProjectRefs.has(projectRefFromUrl(supabaseUrl))
  if (!supabaseUrl || !adminKey || !stripeKey || !successUrl || !cancelUrl) {
    return json({error:'server_configuration_required'},503)
  }
  if (reconciliationMode && !isTestStripeKey(stripeKey)) {
    return json({error:'test_stripe_key_required'},503)
  }

  const admin = createClient(supabaseUrl, adminKey, {auth:{persistSession:false,autoRefreshToken:false}})
  const {data:userData,error:userError} = await admin.auth.getUser(token)
  if (userError || !userData.user) return json({error:'invalid_session'},401)
  if (userData.user.is_anonymous) return json({error:'verified_account_required'},403)

  let payload: {quote_id?:string}
  try { payload = await req.json() } catch { return json({error:'invalid_json'},400) }
  if (!payload.quote_id) return json({error:'quote_id_required'},400)

  const {data:prepared,error:prepareError} = await admin.rpc('evento_prepare_payment_v1', {
    p_user_id:userData.user.id,
    p_quote_id:payload.quote_id,
    p_provider:'stripe',
  })
  if (prepareError || !prepared) {
    const msg = prepareError?.message ?? ''
    if (msg.includes('accepted_contract_required')) return json({error:'accepted_contract_required'},409)
    if (msg.includes('quote_not_accepted')) return json({error:'quote_not_accepted'},409)
    if (msg.includes('forbidden')) return json({error:'forbidden'},403)
    return json({error:'payment_prepare_failed'},500)
  }

  const payment = prepared as Record<string,unknown>
  const amountAed = Number(payment.amount_aed)
  const unitAmount = Math.round(amountAed * 100)
  if (!Number.isFinite(unitAmount) || unitAmount <= 0) return json({error:'invalid_payment_amount'},500)

  const body = new URLSearchParams()
  body.set('mode','payment')
  body.set('success_url',successUrl)
  body.set('cancel_url',cancelUrl)
  body.set('client_reference_id',String(payment.payment_id))
  body.set('integration_identifier','evento_checkout_qpmtxvra')
  body.set('line_items[0][quantity]','1')
  body.set('line_items[0][price_data][currency]','aed')
  body.set('line_items[0][price_data][unit_amount]',String(unitAmount))
  body.set('line_items[0][price_data][product_data][name]','EVENTO Project Development')
  body.set('metadata[evento_payment_id]',String(payment.payment_id))
  body.set('metadata[evento_quote_id]',String(payment.quote_id))
  body.set('metadata[evento_request_id]',String(payment.request_id))
  body.set('payment_intent_data[metadata][evento_payment_id]',String(payment.payment_id))
  body.set('payment_intent_data[metadata][evento_quote_id]',String(payment.quote_id))
  body.set('payment_intent_data[metadata][evento_request_id]',String(payment.request_id))

  const stripeResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
    method:'POST',
    headers:{
      'authorization':`Bearer ${stripeKey}`,
      'content-type':'application/x-www-form-urlencoded',
      'stripe-version':'2026-06-24.dahlia',
    },
    body,
  })
  const stripe = await stripeResponse.json() as Record<string,unknown>
  if (!stripeResponse.ok || !stripe.id || !stripe.url) {
    console.error('Stripe Checkout Session creation failed', stripeResponse.status)
    return json({error:'stripe_checkout_failed'},502)
  }

  const {error:recordError} = await admin.rpc('evento_record_checkout_session_v1', {
    p_payment_id:String(payment.payment_id),
    p_checkout_session_id:String(stripe.id),
    p_checkout_url:String(stripe.url),
  })
  if (recordError) return json({error:'checkout_record_failed'},500)

  return json({
    payment_id:payment.payment_id,
    payment_code:payment.payment_code,
    amount_aed:payment.amount_aed,
    currency:'AED',
    checkout_session_id:stripe.id,
    checkout_url:stripe.url,
  })
})
