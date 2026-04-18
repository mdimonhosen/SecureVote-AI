-- Voters table
CREATE TABLE IF NOT EXISTS voters (
    voter_id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    division TEXT NOT NULL,
    district TEXT NOT NULL,
    upazila TEXT NOT NULL,
    thana TEXT NOT NULL,
    face_embedding JSONB, -- Stores the list of floats
    face_registered BOOLEAN DEFAULT FALSE,
    has_voted BOOLEAN DEFAULT FALSE,
    registration_method TEXT DEFAULT 'csv',
    user_type INT DEFAULT 0, -- 0: Voter, 1: Admin
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Elections table
CREATE TABLE IF NOT EXISTS elections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Candidates table
CREATE TABLE IF NOT EXISTS candidates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    image_url TEXT,
    party TEXT,
    election_id UUID REFERENCES elections(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Votes table (Secure log)
CREATE TABLE IF NOT EXISTS votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    voter_id TEXT REFERENCES voters(voter_id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
    election_id UUID REFERENCES elections(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(voter_id, election_id) -- One person one vote per election
);

-- Storage bucket for candidate and profile images
-- Run this in Supabase Dashboard instead as it requires specific API calls or UI setup
-- Insert placeholder election
INSERT INTO elections (title, description, start_time, end_time, is_active)
VALUES ('National General Election 2026', 'Main democratic election for the country.', NOW(), NOW() + INTERVAL '7 days', TRUE);
