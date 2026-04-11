# /deploy-functions

Deploy Supabase Edge Functions. Always staging first, production only after validation.

## Active Functions
- `send-push-notification` — FCM v1 push delivery
- `send-lockout-notification` — lockout-specific push

## Steps

1. **Identify changed function(s)**
   Read the diff. Confirm which function(s) are modified.

2. **Deploy to staging**
   ```bash
   supabase functions deploy $ARGUMENTS --project-ref $SUPABASE_STAGE_PROJECT_REF --use-api
   ```

3. **Validate on staging**
   Trigger the function via the app running against staging.
   Verify: correct push delivery, no errors in Supabase function logs.
   ```bash
   supabase functions logs $ARGUMENTS --project-ref $SUPABASE_STAGE_PROJECT_REF
   ```

4. **Bayesian gate**
   P(function behaves correctly in production) ≥95%.
   Key risks: env var differences, FCM token format, auth header validation.

5. **Deploy to production**
   ```bash
   supabase functions deploy $ARGUMENTS --project-ref $SUPABASE_PROD_PROJECT_REF --use-api
   ```

6. **Log deployment**
   ```
   docs/claude/confidence-log.md:
   [date] [functions/$ARGUMENTS] [prior→posterior] [validation evidence] [deployed to prod]
   ```

## Environment Variables
Functions read secrets from Supabase Vault — not from .env files.
To update a secret: Supabase dashboard → Project Settings → Edge Functions → Secrets.
