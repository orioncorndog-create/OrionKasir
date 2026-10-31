-- OR!ON CORNDOG POS Professional
-- Phase 2 foundation migration. Additive only: does not drop or rewrite legacy pos_state data.
-- Requires the existing v2.38 schema (pos_profiles + pos_current_role()).
-- Apply only after taking a Supabase database backup.

begin;

create table if not exists public.cash_drawers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cashier_shifts (
  id uuid primary key default gen_random_uuid(),
  shift_mode text not null check (shift_mode in ('individual','shared')),
  cash_drawer_id uuid references public.cash_drawers(id),
  opened_by uuid not null references auth.users(id),
  opened_at timestamptz not null default now(),
  opening_cash numeric(18,2) not null default 0 check (opening_cash >= 0),
  closed_by uuid references auth.users(id),
  closed_at timestamptz,
  status text not null default 'open' check (status in ('open','closed','cancelled')),
  opening_note text,
  closing_note text,
  expected_cash numeric(18,2),
  counted_cash numeric(18,2),
  cash_difference numeric(18,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint shift_mode_drawer_check check (
    (shift_mode = 'individual' and cash_drawer_id is null) or
    (shift_mode = 'shared' and cash_drawer_id is not null)
  ),
  constraint shift_close_values_check check (
    (status <> 'closed') or
    (closed_at is not null and closed_by is not null and expected_cash is not null
     and counted_cash is not null and cash_difference is not null)
  )
);

create unique index if not exists cashier_shifts_one_open_individual_per_user
  on public.cashier_shifts(opened_by) where status = 'open' and shift_mode = 'individual';
create unique index if not exists cashier_shifts_one_open_per_drawer
  on public.cashier_shifts(cash_drawer_id) where status = 'open' and shift_mode = 'shared';
create index if not exists cashier_shifts_opened_at_idx on public.cashier_shifts(opened_at desc);
create index if not exists cashier_shifts_status_idx on public.cashier_shifts(status);

create table if not exists public.shift_members (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid not null references public.cashier_shifts(id),
  user_id uuid not null references auth.users(id),
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  joined_by uuid references auth.users(id),
  left_by uuid references auth.users(id),
  is_shift_lead boolean not null default false,
  unique (shift_id,user_id,joined_at)
);
create index if not exists shift_members_user_active_idx
  on public.shift_members(user_id) where left_at is null;
create index if not exists shift_members_shift_idx on public.shift_members(shift_id);

create table if not exists public.payment_records (
  id uuid primary key default gen_random_uuid(),
  idempotency_key uuid not null unique,
  legacy_sale_id text,
  shift_id uuid references public.cashier_shifts(id),
  cashier_id uuid not null references auth.users(id),
  payment_method text not null,
  gross_amount numeric(18,2) not null check (gross_amount >= 0),
  discount_amount numeric(18,2) not null default 0 check (discount_amount >= 0),
  refund_amount numeric(18,2) not null default 0 check (refund_amount >= 0),
  net_amount numeric(18,2) not null check (net_amount >= 0),
  cash_received numeric(18,2),
  cash_change numeric(18,2),
  status text not null default 'completed' check (status in ('completed','refunded','voided')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (legacy_sale_id)
);
create index if not exists payment_records_shift_idx on public.payment_records(shift_id,created_at);
create index if not exists payment_records_cashier_idx on public.payment_records(cashier_id,created_at desc);

create table if not exists public.cash_movements (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid not null references public.cashier_shifts(id),
  movement_type text not null check (movement_type in ('cash_in','cash_out','cash_refund','cash_drop')),
  amount numeric(18,2) not null check (amount > 0),
  reason text not null,
  reference_id uuid,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists cash_movements_shift_idx on public.cash_movements(shift_id,created_at);

create table if not exists public.shift_reconciliations (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid not null unique references public.cashier_shifts(id),
  opening_cash numeric(18,2) not null,
  cash_sales numeric(18,2) not null default 0,
  cash_refunds numeric(18,2) not null default 0,
  cash_in numeric(18,2) not null default 0,
  cash_out numeric(18,2) not null default 0,
  expected_cash numeric(18,2) not null,
  counted_cash numeric(18,2) not null,
  difference numeric(18,2) not null,
  note text,
  reconciled_by uuid not null references auth.users(id),
  reconciled_at timestamptz not null default now()
);

create table if not exists public.raw_materials (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Lainnya',
  base_unit text not null check (base_unit in ('g','ml','pcs')),
  stock_quantity numeric(18,4) not null default 0 check (stock_quantity >= 0),
  minimum_stock numeric(18,4) not null default 0 check (minimum_stock >= 0),
  purchase_price numeric(18,2) not null default 0 check (purchase_price >= 0),
  purchase_quantity numeric(18,4) not null default 0 check (purchase_quantity >= 0),
  supplier text,
  active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists raw_materials_active_name_idx on public.raw_materials(active,name);

create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  product_key text not null,
  product_name_snapshot text not null,
  version integer not null check (version > 0),
  active boolean not null default false,
  effective_from timestamptz not null default now(),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(product_key,version)
);
create unique index if not exists recipes_one_active_per_product
  on public.recipes(product_key) where active = true;

create table if not exists public.recipe_items (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id),
  raw_material_id uuid not null references public.raw_materials(id),
  quantity numeric(18,4) not null check (quantity > 0),
  unit text not null check (unit in ('g','ml','pcs')),
  created_at timestamptz not null default now(),
  unique(recipe_id,raw_material_id),
  check (unit in ('g','ml','pcs'))
);
create index if not exists recipe_items_recipe_idx on public.recipe_items(recipe_id);
create index if not exists recipe_items_material_idx on public.recipe_items(raw_material_id);

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  raw_material_id uuid not null references public.raw_materials(id),
  movement_type text not null check (movement_type in ('purchase','sale_usage','adjustment_in','adjustment_out','waste','expired','opname','refund_reversal')),
  quantity_delta numeric(18,4) not null check (quantity_delta <> 0),
  stock_before numeric(18,4) not null,
  stock_after numeric(18,4) not null,
  unit text not null check (unit in ('g','ml','pcs')),
  unit_cost_snapshot numeric(18,4),
  reference_type text,
  reference_id text,
  reason text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  check (abs((stock_before + quantity_delta) - stock_after) < 0.0001)
);
create index if not exists stock_movements_material_date_idx
  on public.stock_movements(raw_material_id,created_at desc);
create index if not exists stock_movements_reference_idx
  on public.stock_movements(reference_type,reference_id);

create table if not exists public.operating_expenses (
  id uuid primary key default gen_random_uuid(),
  expense_date date not null default current_date,
  category text not null,
  description text,
  amount numeric(18,2) not null check (amount > 0),
  payment_method text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists operating_expenses_date_idx on public.operating_expenses(expense_date desc);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id),
  action text not null,
  entity_table text not null,
  entity_id text,
  before_data jsonb,
  after_data jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists audit_logs_created_idx on public.audit_logs(created_at desc);
create index if not exists audit_logs_actor_idx on public.audit_logs(actor_id,created_at desc);

create table if not exists public.printer_settings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id),
  label text not null,
  connection_type text not null check (connection_type in ('bluetooth','usb','lan','bridge','browser')),
  paper_width_mm integer not null default 58 check (paper_width_mm in (58,80)),
  config jsonb not null default '{}'::jsonb,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists printer_settings_owner_idx on public.printer_settings(owner_id);

create table if not exists public.printer_logs (
  id uuid primary key default gen_random_uuid(),
  printer_setting_id uuid references public.printer_settings(id),
  sale_reference text,
  operation text not null check (operation in ('test_print','receipt_print','reprint','drawer_kick')),
  status text not null check (status in ('success','failed','unsupported','cancelled')),
  error_message text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists printer_logs_created_idx on public.printer_logs(created_at desc);

-- All newly introduced tables are protected by RLS. Direct browser writes are intentionally
-- not granted yet; the next implementation phase will expose narrowly-scoped SECURITY DEFINER RPCs.
do $$
declare t text;
begin
  foreach t in array array[
    'cash_drawers','cashier_shifts','shift_members','payment_records','cash_movements',
    'shift_reconciliations','raw_materials','recipes','recipe_items','stock_movements',
    'operating_expenses','audit_logs','printer_settings','printer_logs'
  ] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('revoke all on table public.%I from anon, authenticated',t);
  end loop;
end $$;

-- Audit history is append-only, including for privileged application roles.
create or replace function public.orion_prevent_audit_log_mutation()
returns trigger language plpgsql set search_path = '' as $$
begin
  raise exception 'Audit log bersifat append-only';
end;
$$;
drop trigger if exists audit_logs_no_update on public.audit_logs;
create trigger audit_logs_no_update before update or delete on public.audit_logs
for each row execute function public.orion_prevent_audit_log_mutation();

commit;

-- Rollback is intentionally not automated: dropping these tables would destroy any
-- data entered after migration. A reviewed, table-by-table rollback is required.
