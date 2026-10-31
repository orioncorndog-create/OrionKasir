-- OR!ON CORNDOG POS — Phase 4 read RPCs for Shift UI
-- Additive migration. Does not alter or delete existing business records.
begin;

create or replace function public.orion_shift_open_shared()
returns table(
  id uuid,
  opened_at timestamptz,
  opening_cash numeric,
  drawer_name text,
  member_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_uid uuid := public.orion_require_shift_operator();
begin
  return query
  select s.id,s.opened_at,s.opening_cash,d.name,
         count(sm.id) filter (where sm.left_at is null)
  from public.cashier_shifts s
  join public.cash_drawers d on d.id=s.cash_drawer_id
  left join public.shift_members sm on sm.shift_id=s.id
  where s.status='open' and s.shift_mode='shared'
    and not exists (
      select 1 from public.shift_members mine
      join public.cashier_shifts active_shift on active_shift.id=mine.shift_id
      where mine.user_id=v_uid and mine.left_at is null and active_shift.status='open'
    )
  group by s.id,d.name
  order by s.opened_at asc;
end;
$$;

create or replace function public.orion_shift_history(p_limit integer default 30)
returns table(
  id uuid,
  shift_mode text,
  drawer_name text,
  opened_at timestamptz,
  closed_at timestamptz,
  opening_cash numeric,
  expected_cash numeric,
  counted_cash numeric,
  cash_difference numeric,
  status text,
  is_lead boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_require_shift_operator();
  v_role text;
begin
  select p.role into v_role from public.pos_profiles p
  where p.id=v_uid and p.active=true;

  return query
  select s.id,s.shift_mode,d.name,s.opened_at,s.closed_at,s.opening_cash,
         s.expected_cash,s.counted_cash,s.cash_difference,s.status,
         coalesce(bool_or(sm.is_shift_lead and sm.user_id=v_uid),false)
  from public.cashier_shifts s
  left join public.cash_drawers d on d.id=s.cash_drawer_id
  left join public.shift_members sm on sm.shift_id=s.id
  where (v_role in ('owner','manager') or exists(
    select 1 from public.shift_members mine
    where mine.shift_id=s.id and mine.user_id=v_uid
  ) or s.opened_by=v_uid)
  group by s.id,d.name
  order by s.opened_at desc
  limit greatest(1,least(coalesce(p_limit,30),100));
end;
$$;

revoke all on function public.orion_shift_open_shared() from public,anon;
revoke all on function public.orion_shift_history(integer) from public,anon;
grant execute on function public.orion_shift_open_shared() to authenticated;
grant execute on function public.orion_shift_history(integer) to authenticated;

commit;
