CREATE EXTENSION IF NOT EXISTS pg_net;

DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications CASCADE;
DROP FUNCTION IF EXISTS send_push_notification_on_insert() CASCADE;

CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    fcm_token_var TEXT;
    request_id BIGINT;
BEGIN
    SELECT fcm_token INTO fcm_token_var
    FROM users_profiles 
    WHERE id = NEW.user_id 
    AND fcm_token IS NOT NULL
    AND LENGTH(fcm_token) > 50
    LIMIT 1;
    
    IF fcm_token_var IS NOT NULL THEN
        SELECT net.http_post(
            url := 'https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdWVodXdpbXZ3c29xZXNqamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTQ4MTYsImV4cCI6MjA4MDM3MDgxNn0.vhqclBtgt-o_GTNFGsU-pKYK68coeemIjl_CTQl8Rz8'
            ),
            body := jsonb_build_object(
                'fcm_token', fcm_token_var,
                'title', NEW.title,
                'body', NEW.message
            )
        ) INTO request_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

CREATE OR REPLACE FUNCTION mark_notification_as_read(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE notifications 
    SET read_at = NOW()
    WHERE id = notification_id 
    AND user_id = auth.uid()
    AND read_at IS NULL;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_all_notifications_as_read()
RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE notifications 
    SET read_at = NOW()
    WHERE user_id = auth.uid()
    AND read_at IS NULL;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_unread_notifications_count()
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM notifications 
        WHERE user_id = auth.uid()
        AND read_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) 
SELECT 
    au.id,
    '🎉 Sistema Activado',
    'Tu sistema de notificaciones está funcionando correctamente.',
    'system_ready',
    NOW()
FROM auth.users au 
WHERE au.email = 'alof2003@gmail.com'
LIMIT 1;