-- OR!ON CORNDOG POS Professional — Phase 3: Shift Management RPC
-- Additive migration. Requires migration_professional_phase2.sql and v2.38 schema.
-- Run on STAGING first. Does not modify legacy pos_state or historical sales.

begin;

-- Consistent role check. Existing application roles: owner, manager, employee.
create or replace function public.orion_require_shift_operator()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
begin
  if v_uid is null then raise exception 'Login diperlukan'; end if;
  select p.role into v_role
  from public.pos_profiles p
  where p.id = v_uid and p.active = true;

  if v_role is null then raise exception 'Profil POS tidak aktif'; end if;
  if v_role not in ('owner','manager','employee') then
    raise exception 'Role tidak diizinkan mengoperasikan shift';
  end if;
  return v_uid;
end;
$$;

revoke all on function public.orion_require_shift_operator() from public, anon;
grant execute on function public.orion_require_shift_operator() to authenticated;

-- Open an individual shift or a shared cash drawer shift.
create or replace function public.orion_shift_open(
  p_shift_mode text,
  p_opening_cash numeric,
  p_cash_drawer_id uuid default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_require_shift_operator();
  v_shift_id uuid;
begin
  if p_shift_mode not in ('individual','shared') then
    raise exception 'Model shift tidak valid';
  end if;
  if p_opening_cash is null or p_opening_cash < 0 then
    raise exception 'Modal awal tidak boleh negatif';
  end if;

  if p_shift_mode = 'individual' and p_cash_drawer_id is not null then
    raise exception 'Shift individual tidak menggunakan cash drawer bersama';
  end if;
  if exists (
    select 1 from public.shift_members sm
    join public.cashier_shifts s on s.id=sm.shift_id
    where sm.user_id=v_uid and sm.left_at is null and s.status='open'
  ) then
    raise exception 'Anda masih memiliki shift aktif. Tutup atau tinggalkan shift tersebut terlebih dahulu';
  end if;

  if p_shift_mode = 'shared' then
    if p_cash_drawer_id is null then raise exception 'Pilih cash drawer'; end if;
    perform 1 from public.cash_drawers
      where id = p_cash_drawer_id and active = true
      for update;
    if not found then raise exception 'Cash drawer tidak ditemukan atau tidak aktif'; end if;
  end if;

  insert into public.cashier_shifts(
    shift_mode,cash_drawer_id,opened_by,opening_cash,status,opening_note
  ) values (
    p_shift_mode,p_cash_drawer_id,v_uid,p_opening_cash,'open',nullif(trim(p_note),'')
  ) returning id into v_shift_id;

  insert into public.shift_members(shift_id,user_id,joined_by,is_shift_lead)
  values(v_shift_id,v_uid,v_uid,true);

  insert into public.audit_logs(actor_id,action,entity_table,entity_id,after_data)
  values(v_uid,'shift_open','cashier_shifts',v_shift_id::text,
    jsonb_build_object('mode',p_shift_mode,'cash_drawer_id',p_cash_drawer_id,
      'opening_cash',p_opening_cash,'note',p_note));

  return v_shift_id;
exception
  when unique_violation then
    raise exception 'Anda sudah memiliki shift individual aktif atau cash drawer sedang digunakan';
end;
$$;

-- Join an already-open shared drawer. Individual shifts cannot be joined.
create or replace function public.orion_shift_join(p_shift_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_require_shift_operator();
  v_mode text;
begin
  select shift_mode into v_mode
  from public.cashier_shifts
  where id = p_shift_id and status = 'open'
  for update;

  if not found then raise exception 'Shift tidak ditemukan atau sudah ditutup'; end if;
  if v_mode <> 'shared' then raise exception 'Hanya shared cash drawer yang dapat diikuti'; end if;

  if exists (
    select 1 from public.shift_members sm
    join public.cashier_shifts s on s.id=sm.shift_id
    where sm.user_id=v_uid and sm.left_at is null and s.status='open'
  ) then raise exception 'Anda masih tergabung dalam shift aktif lain'; end if;

  insert into public.shift_members(shift_id,user_id,joined_by,is_shift_lead)
  values(p_shift_id,v_uid,v_uid,false);

  insert into public.audit_logs(actor_id,action,entity_table,entity_id,after_data)
  values(v_uid,'shift_join','cashier_shifts',p_shift_id::text,
    jsonb_build_object('user_id',v_uid));
end;
$$;

-- Leave a shared shift without closing the drawer.
create or replace function public.orion_shift_leave(p_shift_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_require_shift_operator();
begin
  update public.shift_members sm
  set left_at=now(), left_by=v_uid
  where sm.shift_id=p_shift_id and sm.user_id=v_uid and sm.left_at is null
    and exists(select 1 from public.cashier_shifts s
      where s.id=p_shift_id and s.status='open' and s.shift_mode='shared');

  if not found then raise exception 'Keanggotaan shift aktif tidak ditemukan'; end if;

  insert into public.audit_logs(actor_id,action,entity_table,entity_id,after_data)
  values(v_uid,'shift_leave','cashier_shifts',p_shift_id::text,
    jsonb_build_object('user_id',v_uid));
end;
$$;

-- Cash in/out/drop movements are recorded separately from sales.
create or replace function public.orion_shift_cash_movement(
  p_shift_id uuid,
  p_movement_type text,
  p_amount numeric,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_require_shift_operator();
  v_id uuid;
begin
  if p_movement_type not in ('cash_in','cash_out','cash_drop') then
    raise exception 'Jenis pergerakan kas tidak valid';
  end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Nominal harus lebih dari nol'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'Alasan wajib diisi'; end if;

  perform 1 from public.cashier_shifts s
  where s.id=p_shift_id and s.status='open'
    and (s.opened_by=v_uid or exists(
      select 1 from public.shift_members sm
      where sm.shift_id=s.id and sm.user_id=v_uid and sm.left_at is null
    ))
  for update;
  if not found then raise exception 'Shift tidak aktif atau Anda bukan anggota shift'; end if;

  insert into public.cash_movements(shift_id,movement_type,amount,reason,created_by)
  values(p_shift_id,p_movement_type,p_amount,trim(p_reason),v_uid)
  returning id into v_id;

  insert into public.audit_logs(actor_id,action,entity_table,entity_id,after_data)
  values(v_uid,'cash_movement','cash_movements',v_id::text,
    jsonb_build_object('shift_id',p_shift_id,'type',p_movement_type,
      'amount',p_amount,'reason',p_reason));
  return v_id;
end;
$$;

-- Close an entire shift/drawer. Only Owner/Manager or the shift opener/lead may close.
-- Cash sales are read from payment_records; legacy JSON-only transactions are not silently guessed.
create or replace function public.orion_shift_close(
  p_shift_id uuid,
  p_counted_cash numeric,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_require_shift_operator();
  v_role text;
  v_shift public.cashier_shifts%rowtype;
  v_cash_sales numeric(18,2) := 0;
  v_cash_refunds numeric(18,2) := 0;
  v_cash_in numeric(18,2) := 0;
  v_cash_out numeric(18,2) := 0;
  v_expected numeric(18,2);
  v_diff numeric(18,2);
  v_result jsonb;
begin
  if p_counted_cash is null or p_counted_cash < 0 then
    raise exception 'Kas fisik tidak boleh negatif';
  end if;

  select p.role into v_role from public.pos_profiles p
  where p.id=v_uid and p.active=true;

  select * into v_shift from public.cashier_shifts
  where id=p_shift_id and status='open'
  for update;
  if not found then raise exception 'Shift tidak ditemukan atau sudah ditutup'; end if;

  if not (
    v_role in ('owner','manager') or v_shift.opened_by=v_uid or exists(
      select 1 from public.shift_members sm
      where sm.shift_id=p_shift_id and sm.user_id=v_uid
        and sm.is_shift_lead=true and sm.left_at is null
    )
  ) then raise exception 'Tidak memiliki izin menutup shift ini'; end if;

  select
    coalesce(sum(case when lower(payment_method) in ('cash','tunai')
      and status='completed' then net_amount else 0 end),0),
    coalesce(sum(case when lower(payment_method) in ('cash','tunai')
      and status='refunded' then refund_amount else 0 end),0)
  into v_cash_sales,v_cash_refunds
  from public.payment_records
  where shift_id=p_shift_id;

  select
    coalesce(sum(case when movement_type='cash_in' then amount else 0 end),0),
    coalesce(sum(case when movement_type in ('cash_out','cash_drop') then amount else 0 end),0)
  into v_cash_in,v_cash_out
  from public.cash_movements
  where shift_id=p_shift_id;

  v_expected := v_shift.opening_cash + v_cash_sales + v_cash_in - v_cash_out - v_cash_refunds;
  v_diff := p_counted_cash - v_expected;

  insert into public.shift_reconciliations(
    shift_id,opening_cash,cash_sales,cash_refunds,cash_in,cash_out,
    expected_cash,counted_cash,difference,note,reconciled_by
  ) values (
    p_shift_id,v_shift.opening_cash,v_cash_sales,v_cash_refunds,v_cash_in,v_cash_out,
    v_expected,p_counted_cash,v_diff,nullif(trim(p_note),''),v_uid
  );

  update public.cashier_shifts
  set status='closed',closed_by=v_uid,closed_at=now(),
      expected_cash=v_expected,counted_cash=p_counted_cash,
      cash_difference=v_diff,closing_note=nullif(trim(p_note),''),
      updated_at=now()
  where id=p_shift_id;

  update public.shift_members
  set left_at=coalesce(left_at,now()),left_by=coalesce(left_by,v_uid)
  where shift_id=p_shift_id and left_at is null;

  insert into public.audit_logs(actor_id,action,entity_table,entity_id,after_data)
  values(v_uid,'shift_close','cashier_shifts',p_shift_id::text,
    jsonb_build_object('expected_cash',v_expected,'counted_cash',p_counted_cash,
      'difference',v_diff,'cash_sales',v_cash_sales,'cash_in',v_cash_in,
      'cash_out',v_cash_out,'cash_refunds',v_cash_refunds));

  v_result := jsonb_build_object(
    'shift_id',p_shift_id,'opening_cash',v_shift.opening_cash,
    'cash_sales',v_cash_sales,'cash_refunds',v_cash_refunds,
    'cash_in',v_cash_in,'cash_out',v_cash_out,
    'expected_cash',v_expected,'counted_cash',p_counted_cash,
    'difference',v_diff,'closed_at',now()
  );
  return v_result;
end;
$$;

-- Owner/Manager can register a shared cash drawer.
create or replace function public.orion_shift_create_drawer(
  p_name text,
  p_code text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_require_shift_operator();
  v_role text;
  v_id uuid;
begin
  select p.role into v_role from public.pos_profiles p
  where p.id=v_uid and p.active=true;
  if v_role not in ('owner','manager') then
    raise exception 'Hanya Owner/Manager yang dapat membuat cash drawer';
  end if;
  if nullif(trim(p_name),'') is null then raise exception 'Nama cash drawer wajib diisi'; end if;

  insert into public.cash_drawers(name,code,created_by)
  values(trim(p_name),nullif(trim(p_code),''),v_uid)
  returning id into v_id;

  insert into public.audit_logs(actor_id,action,entity_table,entity_id,after_data)
  values(v_uid,'cash_drawer_create','cash_drawers',v_id::text,
    jsonb_build_object('name',trim(p_name),'code',p_code));
  return v_id;
exception when unique_violation then
  raise exception 'Kode cash drawer sudah digunakan';
end;
$$;

-- Read current user's active shift. Shared shifts are visible to active members.
create or replace function public.orion_shift_current()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_result jsonb;
begin
  if v_uid is null then raise exception 'Login diperlukan'; end if;

  select jsonb_build_object(
    'id',s.id,'shift_mode',s.shift_mode,'cash_drawer_id',s.cash_drawer_id,
    'opened_by',s.opened_by,'opened_at',s.opened_at,
    'opening_cash',s.opening_cash,'status',s.status,
    'is_lead',sm.is_shift_lead
  ) into v_result
  from public.cashier_shifts s
  join public.shift_members sm on sm.shift_id=s.id
  where s.status='open' and sm.user_id=v_uid and sm.left_at is null
  order by s.opened_at desc limit 1;

  return coalesce(v_result,'null'::jsonb);
end;
$$;

-- Read open drawers for users allowed to operate POS.
create or replace function public.orion_shift_open_drawers()
returns table(id uuid,name text,code text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_uid uuid := public.orion_require_shift_operator();
begin
  return query
  select d.id,d.name,d.code from public.cash_drawers d
  where d.active=true order by d.name;
end;
$$;

-- No direct table access; expose only scoped RPCs.
revoke all on function public.orion_shift_open(text,numeric,uuid,text) from public,anon;
revoke all on function public.orion_shift_join(uuid) from public,anon;
revoke all on function public.orion_shift_leave(uuid) from public,anon;
revoke all on function public.orion_shift_cash_movement(uuid,text,numeric,text) from public,anon;
revoke all on function public.orion_shift_close(uuid,numeric,text) from public,anon;
revoke all on function public.orion_shift_current() from public,anon;
revoke all on function public.orion_shift_open_drawers() from public,anon;
revoke all on function public.orion_shift_create_drawer(text,text) from public,anon;

grant execute on function public.orion_shift_open(text,numeric,uuid,text) to authenticated;
grant execute on function public.orion_shift_join(uuid) to authenticated;
grant execute on function public.orion_shift_leave(uuid) to authenticated;
grant execute on function public.orion_shift_cash_movement(uuid,text,numeric,text) to authenticated;
grant execute on function public.orion_shift_close(uuid,numeric,text) to authenticated;
grant execute on function public.orion_shift_current() to authenticated;
grant execute on function public.orion_shift_open_drawers() to authenticated;
grant execute on function public.orion_shift_create_drawer(text,text) to authenticated;

commit;
