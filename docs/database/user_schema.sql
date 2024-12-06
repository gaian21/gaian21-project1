-- Create extension for strong cryptographic functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Users main table with encrypted data
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username_hash TEXT NOT NULL,  -- Hashed username for searching
    username_encrypted BYTEA NOT NULL,  -- Encrypted actual username
    email_hash TEXT NOT NULL UNIQUE,  -- Hashed email for searching
    email_encrypted BYTEA NOT NULL,  -- Encrypted email
    password_hash TEXT NOT NULL,  -- Argon2 hashed password
    salt TEXT NOT NULL,  -- Unique salt for each user
    creation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    account_status VARCHAR(20) DEFAULT 'active',
    failed_login_attempts INT DEFAULT 0,
    last_password_change TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User sessions for secure authentication
CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    token_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ip_address INET,
    user_agent TEXT
);

-- Security audit log
CREATE TABLE security_audit_log (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    event_type VARCHAR(50) NOT NULL,
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    details JSONB
);

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    token_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE
);

-- Helper functions for encryption/decryption
CREATE OR REPLACE FUNCTION encrypt_text(
    plain_text TEXT,
    encryption_key TEXT
) RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(
        plain_text,
        encryption_key,
        'cipher-algo=aes256'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrypt_text(
    encrypted_data BYTEA,
    encryption_key TEXT
) RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(
        encrypted_data,
        encryption_key
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a new user with encrypted data
CREATE OR REPLACE FUNCTION create_user(
    p_username TEXT,
    p_email TEXT,
    p_password TEXT,
    encryption_key TEXT
) RETURNS UUID AS $$
DECLARE
    new_user_id UUID;
    new_salt TEXT;
BEGIN
    -- Generate salt
    new_salt := gen_salt('bf');
    
    -- Insert new user with encrypted data
    INSERT INTO users (
        id,
        username_hash,
        username_encrypted,
        email_hash,
        email_encrypted,
        password_hash,
        salt
    ) VALUES (
        gen_random_uuid(),
        encode(digest(lower(p_username), 'sha256'), 'hex'),
        encrypt_text(p_username, encryption_key),
        encode(digest(lower(p_email), 'sha256'), 'hex'),
        encrypt_text(p_email, encryption_key),
        crypt(p_password, new_salt),
        new_salt
    ) RETURNING id INTO new_user_id;
    
    -- Log the creation
    INSERT INTO security_audit_log (
        user_id,
        event_type,
        details
    ) VALUES (
        new_user_id,
        'USER_CREATED',
        jsonb_build_object('timestamp', CURRENT_TIMESTAMP)
    );
    
    RETURN new_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to authenticate user
CREATE OR REPLACE FUNCTION authenticate_user(
    p_email TEXT,
    p_password TEXT,
    encryption_key TEXT
) RETURNS TABLE (
    user_id UUID,
    username TEXT,
    authenticated BOOLEAN
) AS $$
DECLARE
    v_user_id UUID;
    v_password_hash TEXT;
    v_username_encrypted BYTEA;
BEGIN
    -- Find user by email hash
    SELECT id, password_hash, username_encrypted
    INTO v_user_id, v_password_hash, v_username_encrypted
    FROM users
    WHERE email_hash = encode(digest(lower(p_email), 'sha256'), 'hex');
    
    IF v_user_id IS NULL THEN
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, FALSE;
        RETURN;
    END IF;
    
    -- Verify password and return result
    IF v_password_hash = crypt(p_password, v_password_hash) THEN
        -- Update last login
        UPDATE users 
        SET last_login = CURRENT_TIMESTAMP,
            failed_login_attempts = 0
        WHERE id = v_user_id;
        
        -- Log successful login
        INSERT INTO security_audit_log (
            user_id,
            event_type,
            details
        ) VALUES (
            v_user_id,
            'LOGIN_SUCCESS',
            jsonb_build_object('timestamp', CURRENT_TIMESTAMP)
        );
        
        RETURN QUERY SELECT 
            v_user_id,
            decrypt_text(v_username_encrypted, encryption_key),
            TRUE;
    ELSE
        -- Update failed login attempts
        UPDATE users 
        SET failed_login_attempts = failed_login_attempts + 1
        WHERE id = v_user_id;
        
        -- Log failed login
        INSERT INTO security_audit_log (
            user_id,
            event_type,
            details
        ) VALUES (
            v_user_id,
            'LOGIN_FAILED',
            jsonb_build_object('timestamp', CURRENT_TIMESTAMP)
        );
        
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;