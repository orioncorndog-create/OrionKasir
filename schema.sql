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
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='pos_state') then
    alter publication supabase_realtime add table public.pos_state;
  end if;
end $$;

-- Profil akun POS: role ditetapkan oleh owner melalui SQL Editor, bukan dari metadata signup.
-- Role tersedia: owner, manager, employee. Jangan memberi hak owner melalui user_metadata.
create table if not exists public.pos_pending_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('manager','employee')),
  display_name text not null default '',
  created_at timestamptz not null default now()
);
revoke all on table public.pos_pending_roles from anon, authenticated;

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
-- Profil POS baru dibuat HANYA setelah email atau nomor HP terverifikasi.
-- Supabase tetap menyimpan auth.users sebagai pending signup; akun itu belum boleh login.
-- Profil employee dibuat saat user terkonfirmasi, bukan saat formulir pendaftaran dikirim.
create or replace function public.pos_create_profile_for_auth_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.email_confirmed_at is not null or new.phone_confirmed_at is not null then
    insert into public.pos_profiles(id, display_name, role, active)
    values (
      new.id,
      coalesce(nullif(new.raw_user_meta_data ->> 'display_name',''), nullif(split_part(coalesce(new.email,''),'@',1),''), new.phone, 'Pengguna'),
      coalesce((select pr.role from public.pos_pending_roles pr where pr.user_id = new.id), 'employee'),
      true
    )
    on conflict (id) do nothing;
    delete from public.pos_pending_roles where user_id = new.id;
  end if;
  return new;
end; $$;
drop trigger if exists on_auth_user_created_pos_profile on auth.users;
drop trigger if exists on_auth_user_verified_pos_profile on auth.users;
create trigger on_auth_user_created_pos_profile after insert on auth.users for each row execute procedure public.pos_create_profile_for_auth_user();
create trigger on_auth_user_verified_pos_profile after update of email_confirmed_at, phone_confirmed_at on auth.users for each row execute procedure public.pos_create_profile_for_auth_user();
-- Bersihkan profil akun yang belum terverifikasi dari instalasi sebelumnya.
delete from public.pos_profiles p using auth.users u
where p.id = u.id and u.email_confirmed_at is null and u.phone_confirmed_at is null;
-- Contoh penetapan role setelah akun dibuat (ganti email dan role):
-- update public.pos_profiles p set role='owner', updated_at=now()
-- from auth.users u where p.id=u.id and u.email='owner@contoh.com';


-- v2.27: hanya owner yang dapat mengubah peran akun melalui aplikasi.
create or replace function public.pos_owner_set_role(target_user_id uuid, new_role text)
returns void language plpgsql security definer set search_path = '' as $$
declare current_role text;
begin
  if new_role not in ('manager','employee') then
    raise exception 'Peran tidak valid';
  end if;
  select role into current_role from public.pos_profiles where id = auth.uid() and active = true;
  if current_role is distinct from 'owner' then
    raise exception 'Hanya owner yang dapat mengatur peran akun';
  end if;
  update public.pos_profiles set role = new_role, updated_at = now() where id = target_user_id;
  if not found then
    if exists (select 1 from auth.users u where u.id = target_user_id and u.email_confirmed_at is null and u.phone_confirmed_at is null) then
      insert into public.pos_pending_roles(user_id, role)
      values (target_user_id, new_role)
      on conflict (user_id) do update set role = excluded.role, created_at = now();
      return;
    end if;
    raise exception 'Profil akun belum tersedia atau akun sudah tidak valid';
  end if;
end; $$;
revoke all on function public.pos_owner_set_role(uuid,text) from public, anon;
grant execute on function public.pos_owner_set_role(uuid,text) to authenticated;

-- v2.38 hardened RPC + storage migration appended below.
-- OR!ON CORNDOG POS v2.38 security + menu image storage migration
-- Jalankan di Supabase SQL Editor menggunakan project owner.
-- Backup database sebelum migrasi. Aplikasi v2.38 memakai RPC, bukan akses tabel langsung.

begin;

-- Role selalu dibaca dari pos_profiles milik server, bukan dari payload/browser.
create or replace function public.pos_current_role()
returns text
language sql stable security definer
set search_path = ''
as $$
  select p.role
  from public.pos_profiles p
  where p.id = (select auth.uid()) and p.active = true
  limit 1;
$$;
revoke all on function public.pos_current_role() from public, anon;
grant execute on function public.pos_current_role() to authenticated;

-- Matikan akses langsung ke snapshot. Hanya RPC di bawah yang dapat membaca/menulis.
alter table public.pos_state enable row level security;
drop policy if exists "pos_state_authenticated_read" on public.pos_state;
drop policy if exists "pos_state_authenticated_insert" on public.pos_state;
drop policy if exists "pos_state_authenticated_update" on public.pos_state;
revoke all on table public.pos_state from anon, authenticated;

create or replace function public.pos_get_state()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text;
  v_payload jsonb;
begin
  v_role := public.pos_current_role();
  if v_role is null then raise exception 'Profil POS tidak aktif atau belum terdaftar'; end if;
  select payload into v_payload from public.pos_state where id = 1;
  if v_payload is null then return '{}'::jsonb; end if;
  if v_role = 'owner' then return v_payload; end if;
  -- Manager dapat melihat keuangan, laporan, transaksi, stok, menu, promo, dan operasional.
  -- Informasi akun/role dan konfigurasi gateway tetap hanya untuk Owner; izin manager dibaca agar dapat dievaluasi di UI.
  v_payload := v_payload - 'users';
  v_payload := jsonb_set(v_payload, '{settings}',
    (coalesce(v_payload->'settings','{}'::jsonb) - 'paymentGateway'), true);
  if v_role = 'manager' then return v_payload; end if;
  -- Kasir hanya menerima data transaksi operasional dan absensi; finance/closing/users disembunyikan.
  v_payload := v_payload - 'finance' - 'closings';
  v_payload := jsonb_set(v_payload, '{settings}',
    (coalesce(v_payload->'settings','{}'::jsonb) - 'paymentGateway' - 'permissions'), true);
  return v_payload;
end;
$$;

create or replace function public.pos_save_state(new_payload jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text;
  v_old jsonb;
  v_next jsonb;
begin
  v_role := public.pos_current_role();
  if v_role is null then raise exception 'Profil POS tidak aktif atau belum terdaftar'; end if;
  if jsonb_typeof(new_payload) <> 'object' then raise exception 'Payload POS tidak valid'; end if;
  select payload into v_old from public.pos_state where id = 1 for update;
  v_old := coalesce(v_old, '{}'::jsonb);
  if v_role = 'owner' then
    v_next := new_payload;
  elsif v_role = 'manager' then
    -- Perubahan dari Manager tidak dapat mengubah akun/role, izin akses, atau konfigurasi gateway.
    v_next := new_payload - 'users';
    v_next := jsonb_set(v_next, '{users}', coalesce(v_old->'users','[]'::jsonb), true);
    v_next := jsonb_set(v_next, '{settings}',
      (coalesce(new_payload->'settings','{}'::jsonb) - 'paymentGateway' - 'permissions') ||
      (coalesce(v_old->'settings','{}'::jsonb) - (coalesce(new_payload->'settings','{}'::jsonb) - 'paymentGateway' - 'permissions')), true);
  else
    -- Kasir hanya boleh menambah/memperbarui penjualan dan absensi; data master/keuangan/setting dipertahankan.
    v_next := v_old;
    if new_payload ? 'sales' then
      v_next := jsonb_set(v_next, '{sales}',
        coalesce(v_old->'sales','[]'::jsonb) ||
        coalesce((select jsonb_agg(incoming.sale) from jsonb_array_elements(coalesce(new_payload->'sales','[]'::jsonb)) as incoming(sale)
          where not exists (select 1 from jsonb_array_elements(coalesce(v_old->'sales','[]'::jsonb)) as prior(sale)
            where prior.sale->>'id' = incoming.sale->>'id')), '[]'::jsonb), true);
    end if;
    if new_payload ? 'attendance' then v_next := jsonb_set(v_next, '{attendance}', new_payload->'attendance', true); end if;
  end if;
  insert into public.pos_state(id,payload,updated_at)
  values (1,v_next,now())
  on conflict (id) do update set payload=excluded.payload, updated_at=excluded.updated_at;
end;
$$;
revoke all on function public.pos_get_state() from public, anon;
revoke all on function public.pos_save_state(jsonb) from public, anon;
grant execute on function public.pos_get_state() to authenticated;
grant execute on function public.pos_save_state(jsonb) to authenticated;

-- Menu image storage. Public read for rendering; writes only by active Owner/Manager.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('orion-menu-images','orion-menu-images',true,12582912,array['image/webp','image/jpeg','image/png'])
on conflict (id) do update set public=true,file_size_limit=12582912,allowed_mime_types=array['image/webp','image/jpeg','image/png'];

drop policy if exists "orion_menu_images_public_read" on storage.objects;
create policy "orion_menu_images_public_read" on storage.objects for select
using (bucket_id='orion-menu-images');
drop policy if exists "orion_menu_images_manager_insert" on storage.objects;
create policy "orion_menu_images_manager_insert" on storage.objects for insert to authenticated
with check (bucket_id='orion-menu-images' and public.pos_current_role() in ('owner','manager'));
drop policy if exists "orion_menu_images_manager_update" on storage.objects;
create policy "orion_menu_images_manager_update" on storage.objects for update to authenticated
using (bucket_id='orion-menu-images' and public.pos_current_role() in ('owner','manager'))
with check (bucket_id='orion-menu-images' and public.pos_current_role() in ('owner','manager'));
drop policy if exists "orion_menu_images_manager_delete" on storage.objects;
create policy "orion_menu_images_manager_delete" on storage.objects for delete to authenticated
using (bucket_id='orion-menu-images' and public.pos_current_role() in ('owner','manager'));

commit;
