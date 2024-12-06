-- Sample users for testing (DO NOT USE IN PRODUCTION)
-- Note: This uses a test encryption key 'test_key_123' - use proper encryption key in production

-- Create test users
SELECT create_user(
    'john_doe',
    'john@example.com',
    'Password123',
    'test_key_123'
);

SELECT create_user(
    'mary_smith',
    'mary@example.com',
    'SecurePass456',
    'test_key_123'
);

SELECT create_user(
    'admin_user',
    'admin@greeksyllector.com',
    'AdminPass789',
    'test_key_123'
);

-- You can test login with these credentials:
-- 1. john@example.com / Password123
-- 2. mary@example.com / SecurePass456
-- 3. admin@greeksyllector.com / AdminPass789