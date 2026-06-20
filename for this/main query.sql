-- ==========================================
-- 1. CREATE POLLS TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS public.polls (
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

-- ==========================================
-- 2. CREATE CANDIDATES TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS public.candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  vote_count INTEGER DEFAULT 0
);

-- ==========================================
-- 3. CREATE VOTES TABLE
-- ==========================================
CREATE TABLE IF NOT EXISTS public.votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES public.users(id),
  candidate_id UUID REFERENCES public.candidates(id),
  casted_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Enforces strict 1-vote-per-user-per-poll rule
  UNIQUE(poll_id, voter_id)
);

-- ==========================================
-- 4. RE-ATTACH THE VOTE COUNTING TRIGGER
-- ==========================================
CREATE OR REPLACE FUNCTION increment_vote_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.candidates SET vote_count = vote_count + 1 WHERE id = NEW.candidate_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_vote_cast ON public.votes;
CREATE TRIGGER on_vote_cast
AFTER INSERT ON public.votes
FOR EACH ROW EXECUTE FUNCTION increment_vote_count();

-- ==========================================
-- 5. RE-APPLY ROW LEVEL SECURITY (RLS)
-- ==========================================
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

-- Polls Policies
DROP POLICY IF EXISTS "Polls are viewable by authenticated users." ON public.polls;
CREATE POLICY "Polls are viewable by authenticated users." ON public.polls FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Only admins can insert polls." ON public.polls;
CREATE POLICY "Only admins can insert polls." ON public.polls FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "Only admins can update or delete polls." ON public.polls;
CREATE POLICY "Only admins can update or delete polls." ON public.polls FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- Candidates Policies
DROP POLICY IF EXISTS "Candidates are viewable by authenticated users." ON public.candidates;
CREATE POLICY "Candidates are viewable by authenticated users." ON public.candidates FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Only admins can insert/update candidates." ON public.candidates;
CREATE POLICY "Only admins can insert/update candidates." ON public.candidates FOR ALL USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- Votes Policies
DROP POLICY IF EXISTS "Users can view their own votes." ON public.votes;
CREATE POLICY "Users can view their own votes." ON public.votes FOR SELECT USING (auth.uid() = voter_id);

DROP POLICY IF EXISTS "Admins can view all votes." ON public.votes;
CREATE POLICY "Admins can view all votes." ON public.votes FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "Approved users can cast a vote." ON public.votes;
CREATE POLICY "Approved users can cast a vote." ON public.votes FOR INSERT WITH CHECK (
  auth.uid() = voter_id AND 
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND status = 'approved')
);