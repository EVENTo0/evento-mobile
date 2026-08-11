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

const hexToBytes = (hex:string) => {
  if (hex.length % 2 !== 0) return new Uint8Array()
  const out = new Uint8Array(hex.length/2)
  for (let i=0;i<out.length;i++) out[i]=Number.parseInt(hex.slice(i*2,i*2+2),16)
  return out
}

async function validStripeSignature(raw:string, header:string, secret:string) {
  const parts = header.split(',').map(v=>v.trim())
  const timestamp = parts.find(v=>v.startsWith('t='))?.slice(2)
  const signatures = parts.filter(v=>v.startsWith('v1=')).map(v=>v.slice(3))
  if (!timestamp || signatures.length===0) return false
  const ts = Number(timestamp)
  if (!Number.isFinite(ts) || Math.abs(Math.floor(Date.now()/1000)-ts)>300) return false
  const key = await crypto.subtle.importKey('raw',new TextEncoder().encode(secret),{name:'HMAC',hash:'SHA-256'},false,['verify'])
  const data = new TextEncoder().encode(`${timestamp}.${raw}`)
  for (const signature of signatures) {
    const sig=hexToBytes(signature)
    if (sig.length && await crypto.subtle.verify('HMAC',key,sig,data)) return true
  }
  return false
}

Deno.serve(async (req:Request) => {
  if (req.method!=='POST') return json({error:'method_not_allowed'},405)
  const webhookSecret=Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? ''
  const supabaseUrl=Deno.env.get('SUPABASE_URL') ?? ''
  const adminKey=getAdminKey()
  if (!webhookSecret || !supabaseUrl || !adminKey) return json({error:'server_configuration_required'},503)

  const signature=req.headers.get('stripe-signature') ?? ''
  const raw=await req.text()
  if (!signature || !(await validStripeSignature(raw,signature,webhookSecret))) return json({error:'invalid_signature'},400)

  let event:Record<string,any>
  try { event=JSON.parse(raw) } catch { return json({error:'invalid_json'},400) }
  const type=String(event.type ?? '')
  if (type!=='checkout.session.completed' && type!=='checkout.session.async_payment_succeeded') return json({received:true,ignored:true})

  const session=event.data?.object as Record<string,any>|undefined
  if (!session?.id) return json({error:'missing_session'},400)
  if (String(session.payment_status ?? '')!=='paid') return json({received:true,payment_status:session.payment_status ?? 'unknown'})

  const amountTotal=Number(session.amount_total)
  const currency=String(session.currency ?? '')
  if (!Number.isFinite(amountTotal) || amountTotal<=0) return json({error:'invalid_amount_total'},400)
  const paymentIntent=typeof session.payment_intent==='string' ? session.payment_intent : ''

  const admin=createClient(supabaseUrl,adminKey,{auth:{persistSession:false,autoRefreshToken:false}})
  const {data,error}=await admin.rpc('evento_mark_payment_paid_v1',{
    p_checkout_session_id:String(session.id),
    p_payment_intent_id:paymentIntent,
    p_provider_event_id:String(event.id ?? ''),
    p_amount_aed:amountTotal/100,
    p_currency:currency,
  })
  if (error) {
    console.error('EVENTO payment reconciliation failed',error.code)
    return json({error:'payment_reconciliation_failed'},500)
  }
  return json({received:true,result:data})
})
