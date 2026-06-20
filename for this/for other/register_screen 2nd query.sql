-- This safely adds all the new columns to your existing users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS present_status TEXT,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS nid_no TEXT,
ADD COLUMN IF NOT EXISTS passport_no TEXT,
ADD COLUMN IF NOT EXISTS face_registered BOOLEAN DEFAULT FALSE;