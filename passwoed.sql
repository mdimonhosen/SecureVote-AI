admin!

mdimonhosen420@gmail.com 
admin1212

general admin!

korim@gmail.com
korim1212

voter!

rohim@gmail.com
rohim1212


akash@gmail.com
akash1212



ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'system_admin';

UPDATE public.users
SET 
  role = 'system_admin', 
  status = 'approved'    
WHERE email = 'korim@gmail.com';