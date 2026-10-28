-- OR!ON CORNDOG POS v2 — Supabase SQL
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
