-- 1. Add new columns to your users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS address TEXT;

-- 2. Create a storage bucket called 'user_images' 
INSERT INTO storage.buckets (id, name, public) 
VALUES ('user_images', 'user_images', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Cleanup existing policies first to avoid errors
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Auth Upload" ON storage.objects;

-- 4. Recreate the Public Access policy
CREATE POLICY "Public Access" ON storage.objects 
FOR SELECT 
USING (bucket_id = 'user_images');

-- 5. Recreate the Auth Upload policy
CREATE POLICY "Auth Upload" ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'user_images' AND auth.role() = 'authenticated');