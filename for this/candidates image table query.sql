-- 1. Add the image_url column to your candidates table
ALTER TABLE public.candidates ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Create a storage bucket called 'candidate_images'
INSERT INTO storage.buckets (id, name, public) 
VALUES ('candidate_images', 'candidate_images', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Allow anyone to view the images
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'candidate_images');

-- 4. Allow Admins to upload images
CREATE POLICY "Admin Upload Access" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'candidate_images' AND 
  EXISTS (SELECT 1 FROM public.users WHERE users.id = auth.uid() AND users.role = 'admin')
);