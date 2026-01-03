# Final Steps: Setting Up Staging Environment

You've already created your staging Supabase project and exported the production schema. Follow these final steps to complete the setup.

## Step 1: Import Schema to Staging

You have your `production_schema.sql` file ready. Import it to staging:

### Option A: Using Supabase Dashboard (Easiest)

1. Go to your **staging** Supabase project dashboard
2. Click on **SQL Editor** in the left sidebar
3. Click **New Query**
4. Open your `production_schema.sql` file
5. Copy the entire contents and paste into the SQL Editor
6. Click **Run** (or press Ctrl+Enter)
7. Wait for it to complete - you should see "Success" messages

**Note:** If you get errors about existing objects, that's okay - the file uses `IF NOT EXISTS` and `CREATE OR REPLACE` in most places.

### Option B: Using Supabase CLI

1. Link to your staging project:
   ```bash
   supabase link --project-ref your-staging-project-ref
   ```

2. Import the schema:
   ```bash
   supabase db push --file production_schema.sql
   ```

## Step 2: Verify Schema Import

1. In staging project, go to **Database** → **Tables**
2. You should see all your tables:
   - app_config
   - calendar_posts
   - connections
   - invite_codes
   - post_exclusions
   - post_media
   - post_reactions
   - post_reports
   - post_tags
   - posts
   - profiles

3. Check **Database** → **Functions** - you should see all your functions
4. Check **Database** → **Tables** → [any table] → **Policies** - RLS policies should be there

## Step 3: Set Up Environment Variables

Update your `.env` file in the project root with staging credentials:

```bash
# Debug mode
APP_DEBUG=true

# Staging Supabase Configuration (for local testing)
SUPABASE_PROJECT_URL=https://your-staging-project.supabase.co
SUPABASE_ANON_KEY=your-staging-anon-key

# GPG Passphrases (if you need Firebase configs later)
GPG_STAGE_CONFIG_PASSPHRASE=your_stage_passphrase
GPG_PRODUCTION_CONFIG_PASSPHRASE=your_production_passphrase
```

**Where to find staging credentials:**
- Go to staging Supabase project → **Settings** → **API**
- Copy the **Project URL** and **anon/public key**

## Step 4: Test the Setup

1. Run the app with staging flavor:
   ```bash
   fvm flutter run --flavor stage
   ```

2. Verify the app connects to staging:
   - Check that you can sign in
   - Check that data loads correctly
   - Verify everything works as expected

## Step 5: Add Test Data (Optional)

Your staging database is empty. You can:

1. **Create test users manually** through the app
2. **Add test posts** to test the feed
3. **Create test connections** to test circle features

Or leave it empty and add data as you test features.

## Quick Reference: Switching Environments

### To Test with Staging (Default for Development):
```bash
# Make sure .env has staging credentials
fvm flutter run --flavor stage
```

### To Test with Production (Only When Needed):
1. Temporarily update `.env` with production credentials
2. Run: `fvm flutter run --flavor production`
3. **Switch back to staging** when done!

## Troubleshooting

### Issue: "SUPABASE_PROJECT_URL not configured"
- Make sure `.env` file exists in project root
- Check that `SUPABASE_PROJECT_URL` and `SUPABASE_ANON_KEY` are set
- Restart your IDE/terminal after updating `.env`

### Issue: Schema import errors
- Some errors are normal (like "already exists")
- Check the error message - if it says "already exists", that's fine
- If you get foreign key errors, make sure all tables were created

### Issue: App can't connect to staging
- Verify `.env` has correct staging credentials
- Check that staging Supabase project is active
- Restart the app after changing `.env`

## You're Done! 🎉

Your staging environment is now set up. Use it for all local development and testing before deploying to production.

**Workflow:**
1. Develop and test in staging (`--flavor stage`)
2. Validate everything works
3. Test once with production before deploying
4. Deploy to production
