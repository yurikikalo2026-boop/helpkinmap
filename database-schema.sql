-- Help Kin Map Database Schema
-- PostgreSQL 14+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- For geolocation features

-- ============================================
-- USERS TABLE
-- ============================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    bio TEXT,
    
    -- Location
    country VARCHAR(100),
    city VARCHAR(100),
    location GEOGRAPHY(POINT, 4326), -- PostGIS point for lat/lng
    
    -- Profile settings
    profile_visibility VARCHAR(20) DEFAULT 'network-only' CHECK (profile_visibility IN ('network-only', 'public')),
    location_sharing BOOLEAN DEFAULT true,
    
    -- Help offerings
    offer_housing BOOLEAN DEFAULT false,
    offer_job BOOLEAN DEFAULT false,
    offer_language BOOLEAN DEFAULT false,
    offer_education BOOLEAN DEFAULT false,
    offer_local BOOLEAN DEFAULT false,
    offer_other BOOLEAN DEFAULT false,
    offer_details TEXT,
    
    -- Authentication
    email_verified BOOLEAN DEFAULT false,
    verification_token VARCHAR(255),
    reset_password_token VARCHAR(255),
    reset_password_expires TIMESTAMP,
    
    -- OAuth
    google_id VARCHAR(255) UNIQUE,
    telegram_id VARCHAR(255) UNIQUE,
    
    -- Preferences
    language VARCHAR(10) DEFAULT 'uk',
    notifications_email BOOLEAN DEFAULT true,
    notifications_push BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    
    -- Search optimization
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(bio, '') || ' ' || coalesce(city, '') || ' ' || coalesce(country, ''))
    ) STORED
);

-- Indexes for users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_location ON users USING GIST(location);
CREATE INDEX idx_users_search ON users USING GIN(search_vector);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_country_city ON users(country, city);

-- ============================================
-- CONNECTIONS TABLE
-- ============================================

CREATE TABLE connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id_1 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_id_2 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    relationship VARCHAR(50) DEFAULT 'friend' CHECK (relationship IN ('family', 'friend', 'colleague', 'other')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    initiated_by UUID NOT NULL REFERENCES users(id),
    notes TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,
    last_interaction TIMESTAMP,
    
    -- Ensure no duplicate connections
    CONSTRAINT unique_connection UNIQUE (user_id_1, user_id_2),
    -- Ensure users can't connect with themselves
    CONSTRAINT no_self_connection CHECK (user_id_1 <> user_id_2)
);

-- Indexes for connections
CREATE INDEX idx_connections_user1 ON connections(user_id_1);
CREATE INDEX idx_connections_user2 ON connections(user_id_2);
CREATE INDEX idx_connections_status ON connections(status);

-- ============================================
-- HELP REQUESTS TABLE
-- ============================================

CREATE TABLE help_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('housing', 'job', 'language', 'education', 'other')),
    
    -- Location
    country VARCHAR(100),
    city VARCHAR(100),
    
    -- Request details
    urgency VARCHAR(20) DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high', 'critical')),
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'in-progress', 'closed', 'fulfilled')),
    visibility VARCHAR(20) DEFAULT 'network-only' CHECK (visibility IN ('network-only', 'public')),
    
    -- Timeline
    needed_by DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    
    -- Assignment
    assigned_to UUID REFERENCES users(id),
    
    -- Metrics
    views INTEGER DEFAULT 0,
    response_count INTEGER DEFAULT 0,
    
    -- Search optimization
    search_vector tsvector GENERATED ALWAYS AS (
        to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(city, '') || ' ' || coalesce(country, ''))
    ) STORED
);

-- Indexes for help_requests
CREATE INDEX idx_help_requests_author ON help_requests(author_id);
CREATE INDEX idx_help_requests_type ON help_requests(type);
CREATE INDEX idx_help_requests_status ON help_requests(status);
CREATE INDEX idx_help_requests_visibility ON help_requests(visibility);
CREATE INDEX idx_help_requests_created_at ON help_requests(created_at DESC);
CREATE INDEX idx_help_requests_search ON help_requests USING GIN(search_vector);

-- ============================================
-- HELP REQUEST RESPONSES TABLE
-- ============================================

CREATE TABLE help_request_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES help_requests(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    responded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_helpful BOOLEAN,
    
    -- Ensure one response per user per request
    CONSTRAINT unique_response UNIQUE (request_id, user_id)
);

-- Indexes for responses
CREATE INDEX idx_responses_request ON help_request_responses(request_id);
CREATE INDEX idx_responses_user ON help_request_responses(user_id);

-- ============================================
-- CONVERSATIONS TABLE
-- ============================================

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(20) DEFAULT '1-on-1' CHECK (type IN ('1-on-1', 'group')),
    name VARCHAR(255), -- For group chats
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP,
    is_archived BOOLEAN DEFAULT false
);

-- Indexes for conversations
CREATE INDEX idx_conversations_created_by ON conversations(created_by);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC);

-- ============================================
-- CONVERSATION PARTICIPANTS TABLE
-- ============================================

CREATE TABLE conversation_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_read_at TIMESTAMP,
    unread_count INTEGER DEFAULT 0,
    is_muted BOOLEAN DEFAULT false,
    
    -- Ensure unique participation
    CONSTRAINT unique_participant UNIQUE (conversation_id, user_id)
);

-- Indexes for participants
CREATE INDEX idx_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX idx_participants_user ON conversation_participants(user_id);

-- ============================================
-- MESSAGES TABLE
-- ============================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'text' CHECK (type IN ('text', 'image', 'file', 'system')),
    
    -- Timestamps
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP,
    
    -- Editing
    is_edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMP,
    
    -- Deletion
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP
);

-- Indexes for messages
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_sent_at ON messages(sent_at DESC);

-- ============================================
-- MESSAGE ATTACHMENTS TABLE
-- ============================================

CREATE TABLE message_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'image', 'document', 'video', etc.
    url TEXT NOT NULL,
    filename VARCHAR(255),
    file_size INTEGER,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for attachments
CREATE INDEX idx_attachments_message ON message_attachments(message_id);

-- ============================================
-- INVITATIONS TABLE
-- ============================================

CREATE TABLE invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    accepted_at TIMESTAMP
);

-- Indexes for invitations
CREATE INDEX idx_invitations_inviter ON invitations(inviter_id);
CREATE INDEX idx_invitations_email ON invitations(email);
CREATE INDEX idx_invitations_token ON invitations(token);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'new-message', 'new-request', 'connection-request', etc.
    title VARCHAR(255) NOT NULL,
    content TEXT,
    link TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

-- Indexes for notifications
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================
-- ACTIVITY LOG TABLE (Optional)
-- ============================================

CREATE TABLE activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for activity log
CREATE INDEX idx_activity_user ON activity_log(user_id);
CREATE INDEX idx_activity_created_at ON activity_log(created_at DESC);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_help_requests_updated_at BEFORE UPDATE ON help_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update response count on help_requests
CREATE OR REPLACE FUNCTION update_response_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE help_requests
        SET response_count = response_count + 1
        WHERE id = NEW.request_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE help_requests
        SET response_count = GREATEST(0, response_count - 1)
        WHERE id = OLD.request_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER help_request_response_count AFTER INSERT OR DELETE ON help_request_responses
    FOR EACH ROW EXECUTE FUNCTION update_response_count();

-- Update unread count
CREATE OR REPLACE FUNCTION update_unread_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversation_participants
    SET unread_count = unread_count + 1
    WHERE conversation_id = NEW.conversation_id
      AND user_id <> NEW.sender_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER message_unread_count AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_unread_count();

-- Update conversation last_message_at
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET last_message_at = NEW.sent_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER conversation_last_message AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_timestamp();

-- ============================================
-- SAMPLE DATA (Optional - for development)
-- ============================================

-- Insert sample users
INSERT INTO users (name, email, password_hash, bio, country, city, location, offer_housing, offer_language, offer_details) VALUES
('Олена Коваленко', 'olena@example.com', '$2b$10$samplehash', 'Викладач англійської мови, з родиною переїхала до Німеччини у 2022 році.', 'Germany', 'Berlin', ST_SetSRID(ST_MakePoint(13.404954, 52.520008), 4326), true, true, 'Можу допомогти з вивченням англійської та німецької мов. Маю досвід викладання 10+ років.'),
('Андрій Мельник', 'andrii@example.com', '$2b$10$samplehash', 'IT спеціаліст, працюю в міжнародній компанії.', 'Poland', 'Warsaw', ST_SetSRID(ST_MakePoint(21.012229, 52.229676), 4326), false, true, 'Можу допомогти з пошуком роботи в IT сфері та вивченням польської мови.'),
('Марія Шевченко', 'maria@example.com', '$2b$10$samplehash', 'Медичний працівник, живу в Канаді 3 роки.', 'Canada', 'Toronto', ST_SetSRID(ST_MakePoint(-79.347015, 43.651070), 4326), true, true, 'Можу надати тимчасове житло та допомогти з адаптацією в Канаді.');

-- Grant permissions (adjust as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO helpkinmap_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO helpkinmap_user;
