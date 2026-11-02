-- OR!ON CORNDOG POS PRO
-- Phase 5 HPP Engine Add-on (ADDITIVE; does not touch pos_state, products, sales, shifts)
-- Prerequisite: existing Phase 5 tables/functions are installed.
-- Apply to STAGING first. Do not rerun Phase 2/3/4/5 migrations.

begin;

-- 1) Record whether a reliable physical stock count is being maintained.
-- Existing rows default to false because their current stock_quantity=0 is not
-- proof that the real-world stock is zero.
alter table public.raw_materials
  add column if not exists stock_tracking_enabled boolean not null default false;

comment on column public.raw_materials.stock_tracking_enabled is
  'False means physical stock is not being tracked; stock_quantity must not be interpreted as actual stock.';

-- 2) Keep the stock-tracking flag truthful when an explicit stock movement is recorded.
-- Until the first purchase/adjustment/opname, legacy zero is displayed as "not tracked".
create or replace function public.orion_inventory_stock_move(
  p_material_id uuid, p_type text, p_quantity numeric, p_reason text,
  p_purchase_price numeric default null
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := public.orion_inventory_require_manager();
  v_m public.raw_materials%rowtype;
  v_delta numeric; v_after numeric; v_id uuid;
begin
  if p_type not in ('purchase','adjustment_in','adjustment_out','waste','expired','opname') then
    raise exception 'Jenis pergerakan tidak valid';
  end if;
  if p_quantity is null or p_quantity <= 0 then raise exception 'Jumlah harus lebih dari nol'; end if;
  select * into v_m from public.raw_materials where id=p_material_id and active=true for update;
  if not found then raise exception 'Bahan tidak ditemukan atau nonaktif'; end if;
  v_delta := case when p_type in ('purchase','adjustment_in') then p_quantity
                  when p_type='opname' then p_quantity-v_m.stock_quantity else -p_quantity end;
  if v_delta=0 then raise exception 'Stok opname tidak mengubah jumlah stok'; end if;
  v_after := v_m.stock_quantity + v_delta;
  if v_after < 0 then raise exception 'Stok tidak mencukupi'; end if;
  update public.raw_materials
  set stock_quantity=v_after,
      stock_tracking_enabled=true,
      purchase_price=case when p_type='purchase' and p_purchase_price is not null then p_purchase_price/p_quantity else purchase_price end,
      purchase_quantity=case when p_type='purchase' then p_quantity else purchase_quantity end,
      updated_at=now()
  where id=p_material_id;
  insert into public.stock_movements(raw_material_id,movement_type,quantity_delta,stock_before,stock_after,unit,unit_cost_snapshot,reason,created_by)
  values(p_material_id,p_type,v_delta,v_m.stock_quantity,v_after,v_m.base_unit,
         case when p_type='purchase' then p_purchase_price else null end,nullif(trim(p_reason),''),v_uid)
  returning id into v_id;
  insert into public.audit_logs(actor_id,action,entity_table,entity_id,before_data,after_data)
  values(v_uid,'inventory_stock_move','raw_materials',p_material_id::text,
         jsonb_build_object('stock',v_m.stock_quantity),
         jsonb_build_object('stock',v_after,'type',p_type,'quantity_delta',v_delta,'movement_id',v_id));
  return jsonb_build_object('movement_id',v_id,'stock_before',v_m.stock_quantity,
                            'stock_after',v_after,'quantity_delta',v_delta);
end;
$$;

-- 3) Update latest purchase price WITHOUT changing physical stock.
-- p_quantity_base is the amount converted to the material base unit (g/ml/pcs).
-- Example: buy 25 kg flour for Rp270000 => p_quantity_base=25000, p_total_cost=270000.
create or replace function public.orion_inventory_update_material_price(
  p_material_id uuid,
  p_quantity_base numeric,
  p_total_cost numeric,
  p_supplier text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_inventory_require_manager();
  v_material public.raw_materials%rowtype;
  v_unit_price numeric(18,4);
begin
  if p_quantity_base is null or p_quantity_base <= 0 then
    raise exception 'Jumlah pembelian dalam satuan dasar harus lebih dari nol';
  end if;
  if p_total_cost is null or p_total_cost < 0 then
    raise exception 'Total harga pembelian tidak valid';
  end if;

  select * into v_material
  from public.raw_materials
  where id = p_material_id and active = true
  for update;
  if not found then raise exception 'Bahan baku tidak ditemukan atau nonaktif'; end if;

  v_unit_price := round(p_total_cost / p_quantity_base, 4);

  update public.raw_materials
  set purchase_price = v_unit_price,
      purchase_quantity = p_quantity_base,
      supplier = coalesce(nullif(trim(p_supplier), ''), supplier),
      updated_at = now()
  where id = p_material_id;

  insert into public.audit_logs(actor_id, action, entity_table, entity_id, before_data, after_data)
  values (
    v_uid,
    'inventory_material_price_update',
    'raw_materials',
    p_material_id::text,
    jsonb_build_object('purchase_price_per_base_unit', v_material.purchase_price,
                       'purchase_quantity', v_material.purchase_quantity,
                       'supplier', v_material.supplier),
    jsonb_build_object('purchase_price_per_base_unit', v_unit_price,
                       'purchase_quantity_base', p_quantity_base,
                       'total_purchase_cost', p_total_cost,
                       'supplier', coalesce(nullif(trim(p_supplier), ''), v_material.supplier),
                       'stock_changed', false)
  );

  return jsonb_build_object(
    'material_id', p_material_id,
    'base_unit', v_material.base_unit,
    'quantity_base', p_quantity_base,
    'total_cost', p_total_cost,
    'unit_cost', v_unit_price,
    'stock_changed', false
  );
end;
$$;

-- 4) Read-only HPP report for every active recipe.
-- HPP is recalculated from current material purchase_price * recipe quantity.
-- Missing/zero prices are flagged; no legacy product.hpp or sales row is updated.
create or replace function public.orion_inventory_hpp_report()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := public.orion_inventory_require_manager();
  v_result jsonb;
begin
  select coalesce(jsonb_agg(x.item order by x.product_name), '[]'::jsonb)
  into v_result
  from (
    select
      r.product_name_snapshot as product_name,
      jsonb_build_object(
        'recipe_id', r.id,
        'product_key', r.product_key,
        'product_name', r.product_name_snapshot,
        'version', r.version,
        'active', r.active,
        'hpp', coalesce(sum(ri.quantity * rm.purchase_price), 0),
        'price_incomplete', coalesce(bool_or(coalesce(rm.purchase_price, 0) <= 0), false),
        'items', coalesce(jsonb_agg(jsonb_build_object(
          'material_id', rm.id,
          'material_name', rm.name,
          'quantity', ri.quantity,
          'unit', ri.unit,
          'unit_price', rm.purchase_price,
          'line_cost', round(ri.quantity * rm.purchase_price, 2)
        ) order by rm.name), '[]'::jsonb)
      ) as item
    from public.recipes r
    join public.recipe_items ri on ri.recipe_id = r.id
    join public.raw_materials rm on rm.id = ri.raw_material_id
    where r.active = true
    group by r.id, r.product_key, r.product_name_snapshot, r.version, r.active
  ) x;

  return v_result;
end;
$$;

revoke all on function public.orion_inventory_update_material_price(uuid,numeric,numeric,text) from public, anon;
revoke all on function public.orion_inventory_hpp_report() from public, anon;
grant execute on function public.orion_inventory_update_material_price(uuid,numeric,numeric,text) to authenticated;
grant execute on function public.orion_inventory_hpp_report() to authenticated;

commit;

-- READ-ONLY verification after applying:
-- select column_name, data_type from information_schema.columns
-- where table_schema='public' and table_name='raw_materials'
-- and column_name='stock_tracking_enabled';
-- select proname from pg_proc join pg_namespace n on n.oid=pronamespace
-- where n.nspname='public' and proname in
-- ('orion_inventory_update_material_price','orion_inventory_hpp_report');
