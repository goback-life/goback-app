// Edge Function: send-lockout-notification
// Sends push notifications to friends when a user starts a lockout
//
// This function should be triggered by a database webhook on lockout_sessions INSERT
//
// Setup:
// 1. Deploy this function: supabase functions deploy send-lockout-notification
// 2. Set secrets: supabase secrets set FCM_SERVER_KEY=your_fcm_key
// 3. Create database webhook in Supabase dashboard:
//    - Table: lockout_sessions
//    - Event: INSERT
//    - Function: send-lockout-notification

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface LockoutPayload {
  type: 'INSERT'
  table: string
  record: {
    id: string
    user_id: string
    started_at: string
    ends_at: string
    action_text?: string
    location_name?: string
  }
}

interface DeviceToken {
  user_id: string
  token: string
  platform: string
}

Deno.serve(async (req) => {
  try {
    const payload: LockoutPayload = await req.json()

    // Only handle INSERT events on lockout_sessions
    if (payload.type !== 'INSERT' || payload.table !== 'lockout_sessions') {
      return new Response(JSON.stringify({ message: 'Ignored event' }), { status: 200 })
    }

    const lockout = payload.record
    const endsAt = new Date(lockout.ends_at)
    const now = new Date()

    // Check if lockout has > 30 minutes remaining (joinable)
    const minutesRemaining = (endsAt.getTime() - now.getTime()) / (1000 * 60)
    if (minutesRemaining < 30) {
      return new Response(
        JSON.stringify({ message: 'Lockout not long enough for push notification' }),
        { status: 200 }
      )
    }

    // Create Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get device tokens for friends who are not in active lockouts
    const { data: tokens, error: tokensError } = await supabase
      .rpc('get_friend_device_tokens_for_lockout', { p_lockout_user_id: lockout.user_id })

    if (tokensError) {
      console.error('Error getting device tokens:', tokensError)
      return new Response(JSON.stringify({ error: tokensError.message }), { status: 500 })
    }

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No friends to notify' }), { status: 200 })
    }

    // Get the lockout user's username for the notification
    const { data: profile } = await supabase
      .from('profiles')
      .select('username')
      .eq('id', lockout.user_id)
      .single()

    const username = profile?.username ?? 'A friend'

    // Send push notifications
    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')
    if (!fcmServerKey) {
      console.error('FCM_SERVER_KEY not set')
      return new Response(JSON.stringify({ error: 'FCM not configured' }), { status: 500 })
    }

    const notifications = (tokens as DeviceToken[]).map(async (deviceToken) => {
      const message = {
        to: deviceToken.token,
        notification: {
          title: 'Friend Locked Out',
          body: `${username} is going offline${lockout.action_text ? ` to ${lockout.action_text}` : ''}. Join them!`,
        },
        data: {
          type: 'lockout_started',
          lockout_id: lockout.id,
          user_id: lockout.user_id,
        },
        // Android specific
        android: {
          priority: 'high',
        },
        // iOS specific
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
      }

      const response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `key=${fcmServerKey}`,
        },
        body: JSON.stringify(message),
      })

      return response.json()
    })

    const results = await Promise.all(notifications)

    return new Response(
      JSON.stringify({
        message: `Sent ${tokens.length} notifications`,
        results,
      }),
      { status: 200 }
    )
  } catch (error) {
    console.error('Error in send-lockout-notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})
