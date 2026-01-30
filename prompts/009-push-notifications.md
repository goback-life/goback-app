<objective>
Implement push notifications for the Goback app using Firebase Cloud Messaging (FCM). Users should receive notifications when friends start lockouts, enabling them to join.

This is the final phase of the lockout feature completion.
</objective>

<context>
Push notifications are essential for the social aspect of Goback:
- When a friend starts a lockout, their friends should be notified
- Tapping the notification opens the app to the lockout screen where they can join
- This drives engagement and the "going back together" experience

Current state:
- In-app notifications exist (`lib/core/features/notification/`)
- Lockout sessions tracked in `lockout_sessions` table
- Friends list available via connections system
- No push notification infrastructure exists yet

@CLAUDE.md for coding patterns
@organisation/DATABASE_SCHEMA_V2.md for schema reference
</context>

<research>
Before implementing, examine:
1. Current notification system in `lib/core/features/notification/`
2. Existing `NotificationType` enum - has `lockoutStarted` and `lockoutJoined`
3. How lockout sessions are created in `LockoutSessionService`
4. Firebase project configuration in `config/` folders
5. Supabase Edge Functions setup (if any exist)
</research>

<requirements>

## Phase 1: Client Infrastructure (~2 hours)

1. **Add Firebase Messaging Dependency**
   - Add `firebase_messaging: ^15.1.6` to pubspec.yaml
   - Ensure Firebase is already configured for the project

2. **Create Device Token Storage**
   - Create Supabase table `device_tokens`:
     ```sql
     CREATE TABLE device_tokens (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
       token TEXT NOT NULL,
       platform TEXT NOT NULL, -- 'ios' or 'android'
       created_at TIMESTAMPTZ DEFAULT NOW(),
       updated_at TIMESTAMPTZ DEFAULT NOW(),
       UNIQUE(user_id, token)
     );

     -- Index for looking up tokens by user
     CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);

     -- RLS policies
     ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

     CREATE POLICY "Users can manage own tokens"
       ON device_tokens FOR ALL
       USING (auth.uid() = user_id);
     ```

3. **Create PushNotificationService**
   - Location: `lib/core/features/notification/data/services/push_notification_service.dart`
   - Responsibilities:
     - Request notification permissions on app start
     - Get FCM token
     - Store/update token in `device_tokens` table
     - Handle token refresh
   - Initialize after successful authentication

4. **Create Device Token Repository**
   - Location: `lib/core/features/notification/data/repositories/device_token_repository.dart`
   - Methods: `saveToken()`, `deleteToken()`, `getTokensForUsers(List<String> userIds)`

## Phase 2: Backend Sending (~3 hours)

5. **Create Supabase Edge Function**
   - Name: `send-lockout-notification`
   - Trigger: Called from database trigger on `lockout_sessions` INSERT
   - Logic:
     1. Get user's friends from `connections` table
     2. Get device tokens for all friends
     3. Build FCM payload with lockout details
     4. Send batch notification via FCM HTTP v1 API

   ```typescript
   // supabase/functions/send-lockout-notification/index.ts
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

   serve(async (req) => {
     const { record } = await req.json() // lockout_sessions row

     // 1. Get friends of the user who started lockout
     // 2. Get their device tokens
     // 3. Send FCM notifications
     // 4. Create in-app notifications
   })
   ```

6. **Create Database Trigger**
   ```sql
   CREATE OR REPLACE FUNCTION trigger_send_lockout_notification()
   RETURNS TRIGGER AS $$
   BEGIN
     -- Call Edge Function via pg_net or http extension
     PERFORM net.http_post(
       url := 'https://<project>.supabase.co/functions/v1/send-lockout-notification',
       body := json_build_object('record', row_to_json(NEW))::text,
       headers := '{"Authorization": "Bearer <service_role_key>"}'
     );
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;

   CREATE TRIGGER trg_send_lockout_notification
     AFTER INSERT ON lockout_sessions
     FOR EACH ROW
     EXECUTE FUNCTION trigger_send_lockout_notification();
   ```

## Phase 3: Client Handling (~1 hour)

7. **Handle Notification Taps**
   - In `PushNotificationService`, handle:
     - `onMessageOpenedApp` - app was in background
     - `getInitialMessage()` - app was terminated
   - Parse notification data to extract `lockout_session_id`
   - Navigate to `ManualLockoutRoutable` or show join dialog

8. **Handle Foreground Notifications**
   - Show local notification or in-app banner when notification received while app is open
   - Option to join directly from the banner

## Files to Create

```
lib/core/features/notification/data/services/push_notification_service.dart
lib/core/features/notification/data/dtos/device_token_dto.dart
lib/core/features/notification/data/repositories/device_token_repository.dart
lib/core/features/notification/data/providers/push_notification_service_provider.dart
lib/core/features/notification/data/providers/device_token_repository_provider.dart
supabase/functions/send-lockout-notification/index.ts
supabase/migrations/xxx_create_device_tokens.sql
supabase/migrations/xxx_add_lockout_notification_trigger.sql
```

## Files to Modify

```
pubspec.yaml - add firebase_messaging dependency
lib/main.dart or startup - initialize push notification service after auth
```

</requirements>

<verification>
After implementation, verify:

1. **Permission Flow**
   - [ ] App requests notification permission on first launch after auth
   - [ ] Permission denial handled gracefully
   - [ ] Permission state persisted

2. **Token Management**
   - [ ] FCM token stored in database after auth
   - [ ] Token refreshes properly handled
   - [ ] Old tokens cleaned up on logout

3. **Notification Sending**
   - [ ] Starting a lockout triggers notification to all friends
   - [ ] Notification contains: username, duration, action text
   - [ ] Edge Function logs show successful sends

4. **Notification Receiving**
   - [ ] Background notification taps open app to lockout screen
   - [ ] Terminated app opens correctly from notification
   - [ ] Foreground notifications show banner/alert

5. **Join Flow**
   - [ ] Tapping notification shows join confirmation
   - [ ] Successful join navigates to lockout screen
   - [ ] Error states handled (expired lockout, already locked out)
</verification>

<notes>
- FCM requires separate setup for iOS (APNs certificates) and Android
- Test on real devices - simulators have limited push notification support
- Consider rate limiting to prevent notification spam
- Edge Function needs FCM service account credentials
- Use FCM HTTP v1 API (not legacy) for better reliability
</notes>
