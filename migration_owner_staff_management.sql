-- OR!ON CORNDOG POS: Owner-only staff directory RPC
-- Run once in Supabase SQL Editor. Does not modify existing staff or sales data.
create or replace function public.pos_owner_list_staff()
returns table (
  user_id uuid,
  email text,
  display_name text,
  role text,
  active boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.pos_profiles p
    where p.id = (select auth.uid())
      and p.active = true
      and p.role = 'owner'
  ) then
    raise exception 'Hanya owner yang dapat melihat daftar karyawan';
  end if;

  return query
  select p.id, u.email::text, p.display_name, p.role, p.active
  from public.pos_profiles p
  join auth.users u on u.id = p.id
  where p.role in ('manager','employee')
  order by lower(p.display_name), lower(coalesce(u.email,''));
end;
$$;

revoke all on function public.pos_owner_list_staff() from public, anon;
grant execute on function public.pos_owner_list_staff() to authenticated;
