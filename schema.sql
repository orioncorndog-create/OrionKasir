-- OR!ON CORNDOG POS v2.9 — Supabase SQL
-- Jalankan pada Supabase SQL Editor. Buat user melalui Authentication > Users.
-- Catatan: pos_state menyimpan snapshot aplikasi untuk prototipe/small outlet.
-- Untuk penggunaan produksi multi-cabang dan audit ketat, normalisasi tabel dan kebijakan role lebih lanjut.

create table if not exists public.pos_state (
  id integer primary key check (id = 1),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.pos_state enable row level security;

-- Hanya pengguna yang login dapat membaca dan menulis snapshot.
drop policy if exists "pos_state_authenticated_read" on public.pos_state;
create policy "pos_state_authenticated_read" on public.pos_state
for select to authenticated using (true);
drop policy if exists "pos_state_authenticated_insert" on public.pos_state;
create policy "pos_state_authenticated_insert" on public.pos_state
for insert to authenticated with check (true);
drop policy if exists "pos_state_authenticated_update" on public.pos_state;
create policy "pos_state_authenticated_update" on public.pos_state
for update to authenticated using (true) with check (true);

insert into public.pos_state (id, payload)
values (1, jsonb_build_object(
  'products', '[]'::jsonb,
  'categories', '[]'::jsonb,
  'promos', '[]'::jsonb,
  'sales', '[]'::jsonb,
  'finance', '[]'::jsonb,
  'attendance', '[]'::jsonb,
  'closings', '[]'::jsonb,
  'settings', jsonb_build_object('outlet','OR!ON CORNDOG','address','','phone','','footer','Terima kasih telah membeli!','lowStock',5),
  'users', '[]'::jsonb
))
on conflict (id) do nothing;

-- Aktifkan Realtime untuk perubahan snapshot:
alter publication supabase_realtime add table public.pos_state;

-- Profil akun POS: role ditetapkan oleh owner melalui SQL Editor, bukan dari metadata signup.
-- Role tersedia: owner, manager, employee. Jangan memberi hak owner melalui user_metadata.
create table if not exists public.pos_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'employee' check (role in ('owner','manager','employee')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.pos_profiles enable row level security;
revoke all on table public.pos_profiles from anon;
grant select on table public.pos_profiles to authenticated;
drop policy if exists "pos_profiles_read_self" on public.pos_profiles;
create policy "pos_profiles_read_self" on public.pos_profiles for select to authenticated using (id = (select auth.uid()));
-- Profile role dibuat otomatis sebagai employee. Role tinggi harus ditetapkan owner melalui SQL Editor.
create or replace function public.pos_create_profile_for_auth_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.pos_profiles(id, display_name, role, active)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(coalesce(new.email,''),'@',1)), 'employee', true)
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created_pos_profile on auth.users;
create trigger on_auth_user_created_pos_profile after insert on auth.users for each row execute procedure public.pos_create_profile_for_auth_user();
-- Contoh penetapan role setelah akun dibuat (ganti email dan role):
-- update public.pos_profiles p set role='owner', updated_at=now()
-- from auth.users u where p.id=u.id and u.email='owner@contoh.com';
