-- Fix storage RLS policies for avatars bucket
-- The avatars bucket exists but INSERT/UPDATE policies were missing,
-- causing "new row violates row-level security policy" on avatar upload.

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;

-- INSERT: authenticated users can upload their own avatar (filename = user ID)
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  name = auth.uid()::text
);

-- SELECT: anyone can view avatars (needed for signed URLs)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- UPDATE: authenticated users can replace their own avatar (needed for upsert)
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  name = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'avatars' AND
  name = auth.uid()::text
);
