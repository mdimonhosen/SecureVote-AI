-- ==============================================================================
-- 1. CLEANUP PREVIOUS TABLES (Safe to run multiple times)
-- ==============================================================================
DROP TRIGGER IF EXISTS on_vote_cast ON public.votes;
DROP FUNCTION IF EXISTS increment_vote_count();
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

DROP TABLE IF EXISTS public.votes CASCADE;
DROP TABLE IF EXISTS public.candidates CASCADE;
DROP TABLE IF EXISTS public.polls CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS user_status CASCADE;

-- ==============================================================================
-- 2. CREATE CUSTOM TYPES
-- ==============================================================================
CREATE TYPE public.user_role AS ENUM ('admin', 'user');
CREATE TYPE public.user_status AS ENUM ('pending', 'approved', 'rejected');

-- ==============================================================================
-- 3. CREATE TABLES
-- ==============================================================================

-- A. USERS TABLE (Includes your requested Auth columns)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  
  -- Core App Logic
  role public.user_role DEFAULT 'user',
  status public.user_status DEFAULT 'pending',
  face_registered BOOLEAN DEFAULT FALSE,
  face_embedding FLOAT8[], -- Stores the ML Kit double array
  
  -- Requested Auth Tracking
  providers TEXT[], 
  provider_type TEXT DEFAULT 'email',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_sign_in_at TIMESTAMPTZ
);

-- B. POLLS TABLE
CREATE TABLE public.polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  is_private BOOLEAN DEFAULT FALSE,
  access_code_hash TEXT, 
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- C. CANDIDATES TABLE
CREATE TABLE public.candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  vote_count INTEGER DEFAULT 0
);

-- D. VOTES TABLE (The Secure Ledger)
CREATE TABLE public.votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES public.users(id),
  candidate_id UUID REFERENCES public.candidates(id),
  casted_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Enforces strict 1-vote-per-user-per-poll rule
  UNIQUE(poll_id, voter_id)
);


-- ==============================================================================
-- 4. SMART DATABASE TRIGGERS & FUNCTIONS
-- ==============================================================================

-- Trigger Function 1: Automate Vote Counting
CREATE OR REPLACE FUNCTION increment_vote_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.candidates
  SET vote_count = vote_count + 1
  WHERE id = NEW.candidate_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_vote_cast
AFTER INSERT ON public.votes
FOR EACH ROW EXECUTE FUNCTION increment_vote_count();


-- Trigger Function 2: Automate User Profile Creation & Default Admin setup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  is_first_user BOOLEAN;
BEGIN
  -- Check if this is the first user in the database
  SELECT count(*) = 0 INTO is_first_user FROM public.users;

  INSERT INTO public.users (
    id, 
    display_name, 
    email, 
    phone, 
    providers, 
    provider_type,
    created_at, 
    last_sign_in_at,
    role,         -- The Smart Admin Logic
    status        -- The Smart Approval Logic
  )
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'Unknown User'),
    new.email,
    new.phone,
    ARRAY[new.raw_app_meta_data->>'provider'],
    COALESCE(new.raw_app_meta_data->>'provider', 'email'),
    new.created_at,
    new.last_sign_in_at,
    
    -- If it's the first user, make them 'admin'. Otherwise, 'user'.
    CASE WHEN is_first_user THEN 'admin'::public.user_role ELSE 'user'::public.user_role END,
    
    -- If it's the first user, auto-approve them. Otherwise, set to 'pending'.
    CASE WHEN is_first_user THEN 'approved'::public.user_status ELSE 'pending'::public.user_status END
  );
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Bind the trigger to Supabase's hidden Auth table
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- Trigger Function 3: Sync "Last Sign In At" automatically
CREATE OR REPLACE FUNCTION public.sync_last_sign_in()
RETURNS trigger AS $$
BEGIN
  IF NEW.last_sign_in_at IS DISTINCT FROM OLD.last_sign_in_at THEN
    UPDATE public.users 
    SET last_sign_in_at = NEW.last_sign_in_at
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.sync_last_sign_in();

-- ==============================================================================
-- END OF SCRIPT
-- ==============================================================================