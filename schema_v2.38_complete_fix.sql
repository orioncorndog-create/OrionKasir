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
