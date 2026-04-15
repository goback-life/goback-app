-- Add deleted_at column to posts (exists in production but was missing from migrations).
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS deleted_at timestamptz;
