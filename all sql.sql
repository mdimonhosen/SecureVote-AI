-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table (extends auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  approved BOOLEAN DEFAULT FALSE,
  is_admin BOOLEAN DEFAULT FALSE,
  face_person_id TEXT, -- For Microsoft Face API person ID
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create polls table
CREATE TABLE polls (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_private BOOLEAN DEFAULT FALSE,
  security_code TEXT, -- For private polls
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create candidates table
CREATE TABLE candidates (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- If candidate is a registered user
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create votes table
CREATE TABLE votes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  candidate_id UUID REFERENCES candidates(id) ON DELETE CASCADE,
  voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, poll_id) -- One vote per user per poll
);

-- Create invited_users table for private polls
CREATE TABLE invited_users (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(poll_id, user_id)
);

-- Row Level Security (RLS) policies

-- Profiles: Users can read/update their own profile, admins can read all
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Polls: Everyone can read active polls, admins can manage all
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active polls" ON polls
  FOR SELECT USING (
    start_date <= NOW() AND end_date >= NOW()
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Admins can manage polls" ON polls
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Candidates: Public for active polls
ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View candidates for active polls" ON candidates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM polls
      WHERE polls.id = candidates.poll_id
      AND start_date <= NOW() AND end_date >= NOW()
    )
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Votes: Users can insert their own, admins can view all
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own votes" ON votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own votes" ON votes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all votes" ON votes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- Invited users: Admins can manage, users can view their invites
ALTER TABLE invited_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage invites" ON invited_users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Users can view their invites" ON invited_users
  FOR SELECT USING (auth.uid() = user_id);

-- Functions and triggers

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'name', NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to check if user can vote in poll
CREATE OR REPLACE FUNCTION can_vote(poll_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  poll_record RECORD;
  is_invited BOOLEAN;
BEGIN
  SELECT * INTO poll_record FROM polls WHERE id = poll_id;
  
  IF poll_record.is_private THEN
    SELECT EXISTS(
      SELECT 1 FROM invited_users 
      WHERE invited_users.poll_id = poll_id AND invited_users.user_id = user_id
    ) INTO is_invited;
    RETURN is_invited;
  ELSE
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================
-- ADMIN SETUP INSTRUCTIONS (UPDATED)
-- ===================================================
-- To create an admin account with email: admin@gmail.com and password: admin123
-- 
-- IMPORTANT: Passwords are managed in auth.users (encrypted), NOT in profiles table
-- The app now automatically creates missing profiles on first login
-- ===================================================

-- STEP 1: Create the auth user (do this in Supabase Dashboard)
--   - Go to Supabase Dashboard > Authentication > Users
--   - Click "Add user" > "Create new user"
--   - Email: admin@gmail.com
--   - Password: admin123
--   - Auto confirm user: YES
--   - This will automatically create a profile via the trigger

-- STEP 2: Wait 5 seconds, then verify profile was created
--   Run this query to check:
--   SELECT id, name, email, is_admin, approved FROM profiles WHERE email = 'admin@gmail.com';
--   You should see a row with is_admin=false, approved=false

-- STEP 3: If profile exists, promote to admin by running this SQL:
--   UPDATE profiles 
--   SET is_admin = true, approved = true 
--   WHERE email = 'admin@gmail.com';
--
--   If profile doesn't exist, run this SQL to create and promote:
--   INSERT INTO profiles (id, name, email, approved, is_admin)
--   SELECT id, email, email, true, true FROM auth.users WHERE email = 'admin@gmail.com'
--   ON CONFLICT(id) DO UPDATE SET is_admin = true, approved = true;

-- STEP 4: Verify the admin promotion worked:
--   SELECT id, name, email, is_admin, approved FROM profiles WHERE email = 'admin@gmail.com';
--   You should see is_admin=true, approved=true

-- STEP 5: Login to the app with:
--   - Email: admin@gmail.com
--   - Password: admin123
--   - You will see "Loading your profile..." briefly
--   - Then you will see the Admin Dashboard

-- ===================================================
-- TROUBLESHOOTING
-- ===================================================
-- Issue: Still going to User Dashboard after login?
--   Solution 1: Check that is_admin=true in the database (see STEP 4)
--   Solution 2: Clear app cache/data and login again
--   Solution 3: Check browser console for errors
--   Solution 4: Make sure profile has approved=true
--
-- Issue: Stuck on "Loading your profile..." screen?
--   Solution: Check that profiles table is not blocked by RLS policies
--   Solution: Ensure user can read their own profile
--
-- To manually fix any user's admin status, run:
--   UPDATE profiles SET is_admin = true WHERE email = 'desired_email@example.com';
-- ===================================================

-- Sample data: Uncomment and update UUID after creating admin via auth
-- INSERT INTO profiles (id, name, email, approved, is_admin) VALUES ('00000000-0000-0000-0000-000000000001', 'Admin', 'admin@gmail.com', TRUE, TRUE);