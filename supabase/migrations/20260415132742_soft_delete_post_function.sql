-- Add the soft_delete_post RPC function (exists in production but was missing from migrations).
CREATE OR REPLACE FUNCTION public.soft_delete_post(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.posts
    SET deleted_at = NOW()
    WHERE id = post_id;
END;
$$;

ALTER FUNCTION public.soft_delete_post(post_id uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.soft_delete_post(post_id uuid) TO anon;
GRANT ALL ON FUNCTION public.soft_delete_post(post_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.soft_delete_post(post_id uuid) TO service_role;
