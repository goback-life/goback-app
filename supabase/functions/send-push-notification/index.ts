// Edge Function: send-push-notification
// Unified push notification handler using FCM v1 HTTP API.
// Triggered by DB webhook on push_notification_queue INSERT.
//
// Setup:
// 1. Deploy: supabase functions deploy send-push-notification
// 2. Set secret: supabase secrets set FCM_SERVICE_ACCOUNT_JSON='<json>'
// 3. Create DB webhook: push_notification_queue INSERT → send-push-notification

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Types ───────────────────────────────────────────────────────────────────

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: {
    id: string
    event_type: string
    payload: Record<string, string>
    created_at: string
    processed_at: string | null
    process_after: string
  }
}

interface DeviceToken {
  user_id: string
  token: string
  platform: string
}

interface FcmMessage {
  title: string
  body: string
  data: Record<string, string>
  tokens: DeviceToken[]
  androidPriority: 'high' | 'normal'
  iosInterruptionLevel: 'active' | 'passive'
}

interface ServiceAccount {
  client_email: string
  private_key: string
  token_uri: string
  project_id: string
}

// ── JWT / OAuth2 helpers ────────────────────────────────────────────────────

function base64url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
}

function strToBase64url(str: string): string {
  return base64url(new TextEncoder().encode(str))
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const lines = pem.split('\n').filter(l => !l.startsWith('-----') && l.trim())
  const der = Uint8Array.from(atob(lines.join('')), c => c.charCodeAt(0))
  return crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'])
}

async function createSignedJwt(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = strToBase64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = strToBase64url(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: sa.token_uri,
    iat: now,
    exp: now + 3600,
  }))
  const key = await importPrivateKey(sa.private_key)
  const sig = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${payload}`)))
  return `${header}.${payload}.${base64url(sig)}`
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const jwt = await createSignedJwt(sa)
  const res = await fetch(sa.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  if (!res.ok) throw new Error(`Token exchange failed: ${res.status} ${await res.text()}`)
  const { access_token } = await res.json()
  return access_token
}

// ── FCM v1 sender ───────────────────────────────────────────────────────────

async function sendFcm(
  accessToken: string,
  projectId: string,
  token: DeviceToken,
  msg: FcmMessage,
): Promise<{ token: string; success: boolean; unregistered: boolean }> {
  const isIos = token.platform === 'ios'
  const body = {
    message: {
      token: token.token,
      notification: { title: msg.title, body: msg.body },
      data: msg.data,
      android: {
        priority: msg.androidPriority,
        notification: { channel_id: 'push_notifications' },
      },
      apns: {
        headers: {
          'apns-priority': msg.iosInterruptionLevel === 'passive' ? '5' : '10',
        },
        payload: {
          aps: {
            alert: { title: msg.title, body: msg.body },
            sound: msg.iosInterruptionLevel === 'passive' ? null : 'default',
            'interruption-level': msg.iosInterruptionLevel,
          },
        },
      },
    },
  }

  try {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      },
    )
    if (!res.ok) {
      const err = await res.json().catch(() => ({}))
      const code = err?.error?.details?.[0]?.errorCode ?? err?.error?.status ?? ''
      return { token: token.token, success: false, unregistered: code === 'UNREGISTERED' }
    }
    return { token: token.token, success: true, unregistered: false }
  } catch {
    return { token: token.token, success: false, unregistered: false }
  }
}

// ── Event routing ───────────────────────────────────────────────────────────

async function buildMessage(
  supabase: ReturnType<typeof createClient>,
  eventType: string,
  payload: Record<string, string>,
): Promise<FcmMessage | null> {
  const getUsername = async (userId: string): Promise<string> => {
    const { data } = await supabase.from('profiles').select('username').eq('id', userId).single()
    return data?.username ?? 'Someone'
  }

  switch (eventType) {
    case 'lockout_started': {
      const { data: tokens } = await supabase.rpc('get_friend_device_tokens_for_lockout', { p_lockout_user_id: payload.user_id })
      if (!tokens?.length) return null
      const username = await getUsername(payload.user_id)
      const locationName = payload.location_name
      const isOpenEnded = payload.is_open_ended === 'true' || payload.is_open_ended === true
      const body = locationName
        ? `${username} is going back at ${locationName}. Tap to join!`
        : `${username} is going offline. Join them!`
      return {
        title: isOpenEnded ? 'Friend at a GoBack Venue' : 'Friend Locked Out',
        body,
        data: { type: 'lockout_started', lockout_id: payload.lockout_id },
        tokens,
        androidPriority: 'high',
        iosInterruptionLevel: 'active',
      }
    }

    case 'friend_joins_lockout': {
      const { data: tokens } = await supabase.rpc('get_friend_device_tokens_for_user', { p_user_id: payload.joiner_id })
      if (!tokens?.length) return null
      const joinerName = await getUsername(payload.joiner_id)
      const ownerName = await getUsername(payload.owner_id)
      return {
        title: 'Friend Locked Out',
        body: `${joinerName} joined ${ownerName}'s lockout. Join them!`,
        data: { type: 'friend_joins_lockout', lockout_id: payload.lockout_id },
        tokens,
        androidPriority: 'high',
        iosInterruptionLevel: 'active',
      }
    }

    case 'lockout_completed': {
      // Notify a participant that the leader ended the venue lockout
      const { data: tokens } = await supabase.rpc('get_user_device_tokens', { p_user_id: payload.user_id })
      if (!tokens?.length) return null
      const venueName = payload.venue_name
      const body = venueName
        ? `Your lockout at ${venueName} has ended`
        : 'Your lockout has ended'
      return {
        title: 'Lockout ended',
        body,
        data: { type: 'lockout_completed', lockout_id: payload.lockout_id },
        tokens,
        androidPriority: 'high',
        iosInterruptionLevel: 'active',
      }
    }

    case 'venue_departure': {
      // Informational: someone left the venue (their lockout continues)
      const { data: tokens } = await supabase.rpc('get_user_device_tokens', { p_user_id: payload.user_id })
      if (!tokens?.length) return null
      const departedUsername = payload.departed_username || 'Someone'
      const venueName = payload.venue_name
      const body = venueName
        ? `${departedUsername} left ${venueName}`
        : `${departedUsername} ended their lockout`
      return {
        title: 'goback update',
        body,
        data: { type: 'venue_departure', lockout_id: payload.lockout_id },
        tokens,
        androidPriority: 'normal' as const,
        iosInterruptionLevel: 'passive' as const,
      }
    }

    case 'connection_request': {
      const { data: tokens } = await supabase.rpc('get_user_device_tokens', { p_user_id: payload.receiver_id })
      if (!tokens?.length) return null
      const senderName = await getUsername(payload.sender_id)
      return {
        title: 'New Friend Request',
        body: `${senderName} wants to connect with you`,
        data: { type: 'connection_request', request_id: payload.request_id },
        tokens,
        androidPriority: 'high',
        iosInterruptionLevel: 'active',
      }
    }

    case 'member_joined_batch': {
      const sessionId = payload.session_id
      const joinerUsernames: string[] = (payload.joiner_usernames ?? []) as unknown as string[]
      const joinerUserIds: string[] = (payload.joiner_user_ids ?? []) as unknown as string[]

      if (!joinerUsernames.length || !joinerUserIds.length) return null

      // Get device tokens for all current participants, excluding the joiners
      const { data: tokens } = await supabase.rpc('get_lockout_participant_tokens', {
        p_session_id: sessionId,
        p_exclude_user_ids: joinerUserIds,
      })
      if (!tokens?.length) return null

      // Build message based on joiner count
      const count = joinerUsernames.length
      const latest = joinerUsernames[joinerUsernames.length - 1]
      let body: string
      if (count === 1) {
        body = `${latest} joined your lockout`
      } else if (count === 2) {
        body = `${joinerUsernames[0]} and ${joinerUsernames[1]} joined your lockout`
      } else {
        body = `${latest} and ${count - 1} others joined your lockout`
      }

      return {
        title: 'goback',
        body,
        data: { type: 'member_joined', lockout_id: sessionId },
        tokens,
        androidPriority: 'normal',
        iosInterruptionLevel: 'passive',
      }
    }

    default:
      console.warn(`Unknown event type: ${eventType}`)
      return null
  }
}

// ── Main handler ────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    const webhookPayload: WebhookPayload = await req.json()

    if (webhookPayload.type !== 'INSERT' || webhookPayload.table !== 'push_notification_queue') {
      return new Response(JSON.stringify({ message: 'Ignored event' }), { status: 200 })
    }

    const { id, event_type, payload } = webhookPayload.record

    // Skip events that aren't ready to process yet (batched by pg_cron)
    if (webhookPayload.record.process_after && new Date(webhookPayload.record.process_after) > new Date()) {
      return new Response(JSON.stringify({ message: 'Deferred for batching' }), { status: 200 })
    }

    // Parse service account
    const saJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')
    if (!saJson) {
      console.error('FCM_SERVICE_ACCOUNT_JSON not set')
      return new Response(JSON.stringify({ error: 'FCM not configured' }), { status: 500 })
    }
    const sa: ServiceAccount = JSON.parse(saJson)

    // Supabase client (service role)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Build message for this event type
    const msg = await buildMessage(supabase, event_type, payload)
    if (!msg) {
      // No recipients — mark processed and return
      await supabase.from('push_notification_queue').update({ processed_at: new Date().toISOString() }).eq('id', id)
      return new Response(JSON.stringify({ message: 'No recipients' }), { status: 200 })
    }

    // Get FCM access token
    const accessToken = await getAccessToken(sa)

    // Send to all tokens
    const results = await Promise.all(
      msg.tokens.map(t => sendFcm(accessToken, sa.project_id, t, msg)),
    )

    // Clean up unregistered tokens
    const staleTokens = results.filter(r => r.unregistered).map(r => r.token)
    if (staleTokens.length > 0) {
      await supabase.from('device_tokens').delete().in('token', staleTokens)
      console.log(`Cleaned ${staleTokens.length} stale token(s)`)
    }

    // Mark processed
    await supabase
      .from('push_notification_queue')
      .update({ processed_at: new Date().toISOString() })
      .eq('id', id)

    const sent = results.filter(r => r.success).length
    return new Response(
      JSON.stringify({ message: `Sent ${sent}/${results.length} notifications`, event_type }),
      { status: 200 },
    )
  } catch (error) {
    console.error('Error in send-push-notification:', error)
    return new Response(JSON.stringify({ error: (error as Error).message }), { status: 500 })
  }
})
