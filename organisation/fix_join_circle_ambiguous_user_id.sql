-- Fix ambiguous user_id reference in join_circle_transaction function
-- This fixes PostgreSQL error 42702: column reference "user_id" is ambiguous

CREATE OR REPLACE FUNCTION public.join_circle_transaction(invite_id uuid, user_id uuid, creator_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Check if invite code is still valid and not used
    IF NOT EXISTS (
        SELECT 1 FROM invite_codes 
        WHERE id = invite_id 
        AND used_by_id IS NULL 
        AND expires_at > NOW()
    ) THEN
        RAISE EXCEPTION 'Invite code is invalid, expired, or already used';
    END IF;
    
    -- Check if users are not already connected
    IF EXISTS (
        SELECT 1 FROM connections 
        WHERE (connections.user_id = join_circle_transaction.user_id AND connections.connection_id = join_circle_transaction.creator_id)
        OR (connections.user_id = join_circle_transaction.creator_id AND connections.connection_id = join_circle_transaction.user_id)
    ) THEN
        RAISE EXCEPTION 'Users are already connected';
    END IF;
    
    -- Check if joiner has reached circle size limit (150)
    IF (
        SELECT COUNT(*) FROM connections 
        WHERE connections.user_id = join_circle_transaction.user_id 
           OR connections.connection_id = join_circle_transaction.user_id
    ) >= 150 THEN
        RAISE EXCEPTION 'User has reached maximum circle size of 150';
    END IF;

    -- Check if creator has reached circle size limit (150)
    IF (
        SELECT COUNT(*) FROM connections 
        WHERE connections.user_id = join_circle_transaction.creator_id 
           OR connections.connection_id = join_circle_transaction.creator_id
    ) >= 150 THEN
        RAISE EXCEPTION 'Creator has reached maximum circle size of 150';
    END IF;
    
    -- Mark invite code as used
    UPDATE invite_codes 
    SET used_by_id = join_circle_transaction.user_id 
    WHERE id = invite_id;
    
    -- Create single connection row (always put the smaller UUID first for consistency)
    INSERT INTO connections (user_id, connection_id) VALUES 
    (
        CASE 
            WHEN join_circle_transaction.user_id < join_circle_transaction.creator_id 
            THEN join_circle_transaction.user_id 
            ELSE join_circle_transaction.creator_id 
        END,
        CASE 
            WHEN join_circle_transaction.user_id < join_circle_transaction.creator_id 
            THEN join_circle_transaction.creator_id 
            ELSE join_circle_transaction.user_id 
        END
    );
END;
$$;

