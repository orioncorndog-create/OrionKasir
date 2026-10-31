-- OR!ON CORNDOG POS Professional - Phase 5 Inventory & BOM
-- Additive migration. Run after Phase 2 + Phase 3 migrations on staging first.
-- Does not alter legacy pos_state, products, or historical sales.
begin;
create or replace function public.orion_inventory_require_manager()
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_role text;
begin
 if v_uid is null then raise exception 'Login diperlukan'; end if;
 select role into v_role from public.pos_profiles where id=v_uid and active=true;
 if v_role is null or v_role not in ('owner','admin','manager') then raise exception 'Akses inventaris hanya untuk Owner/Manajer'; end if;
 return v_uid;
end; $$;

create or replace function public.orion_inventory_list()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := public.orion_inventory_require_manager(); v_materials jsonb; v_recipes jsonb; v_moves jsonb;
begin
 select coalesce(jsonb_agg(to_jsonb(m) order by m.active desc,m.name),'[]'::jsonb) into v_materials from public.raw_materials m;
 select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'product_key',r.product_key,'product_name_snapshot',r.product_name_snapshot,'version',r.version,'active',r.active,'effective_from',r.effective_from,'items',coalesce((select jsonb_agg(jsonb_build_object('id',ri.id,'raw_material_id',ri.raw_material_id,'material_name',rm.name,'quantity',ri.quantity,'unit',ri.unit) order by rm.name) from public.recipe_items ri join public.raw_materials rm on rm.id=ri.raw_material_id where ri.recipe_id=r.id),'[]'::jsonb)) order by r.product_name_snapshot,r.version desc),'[]'::jsonb) into v_recipes from public.recipes r;
 select coalesce(jsonb_agg(jsonb_build_object('id',sm.id,'raw_material_id',sm.raw_material_id,'material_name',rm.name,'movement_type',sm.movement_type,'quantity_delta',sm.quantity_delta,'stock_before',sm.stock_before,'stock_after',sm.stock_after,'unit',sm.unit,'reason',sm.reason,'created_at',sm.created_at) order by sm.created_at desc),'[]'::jsonb) into v_moves from (select * from public.stock_movements order by created_at desc limit 100) sm join public.raw_materials rm on rm.id=sm.raw_material_id;
 return jsonb_build_object('materials',v_materials,'recipes',v_recipes,'movements',v_moves);
end; $$;

create or replace function public.orion_inventory_save_material(p_id uuid,p_name text,p_category text,p_unit text,p_minimum numeric,p_supplier text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_uid uuid:=public.orion_inventory_require_manager(); v_id uuid;
begin
 if nullif(trim(p_name),'') is null then raise exception 'Nama bahan wajib diisi'; end if;
 if p_unit not in ('g','ml','pcs') then raise exception 'Satuan harus g, ml, atau pcs'; end if;
 if coalesce(p_minimum,0)<0 then raise exception 'Stok minimum tidak valid'; end if;
 if p_id is null then
  insert into public.raw_materials(name,category,base_unit,minimum_stock,supplier,created_by) values(trim(p_name),coalesce(nullif(trim(p_category),''),'Lainnya'),p_unit,coalesce(p_minimum,0),nullif(trim(p_supplier),''),v_uid) returning id into v_id;
 else
  if exists(select 1 from public.raw_materials where id=p_id and base_unit<>p_unit) and (exists(select 1 from public.stock_movements where raw_material_id=p_id) or exists(select 1 from public.recipe_items where raw_material_id=p_id)) then raise exception 'Satuan dasar tidak dapat diubah karena bahan sudah memiliki riwayat stok atau resep'; end if;
  update public.raw_materials set name=trim(p_name),category=coalesce(nullif(trim(p_category),''),'Lainnya'),base_unit=p_unit,minimum_stock=coalesce(p_minimum,0),supplier=nullif(trim(p_supplier),''),updated_at=now() where id=p_id returning id into v_id;
  if v_id is null then raise exception 'Bahan baku tidak ditemukan'; end if;
 end if;
 insert into public.audit_logs(actor_id,action,entity_table,entity_id,after_data) values(v_uid,'inventory_material_save','raw_materials',v_id::text,jsonb_build_object('name',p_name,'unit',p_unit,'minimum_stock',p_minimum));
 return v_id;
end; $$;

create or replace function public.orion_inventory_stock_move(p_material_id uuid,p_type text,p_quantity numeric,p_reason text,p_purchase_price numeric default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid:=public.orion_inventory_require_manager(); v_m public.raw_materials%rowtype; v_delta numeric; v_after numeric; v_id uuid;
begin
 if p_type not in ('purchase','adjustment_in','adjustment_out','waste','expired','opname') then raise exception 'Jenis pergerakan tidak valid'; end if;
 if p_quantity is null or p_quantity<=0 then raise exception 'Jumlah harus lebih dari nol'; end if;
 select * into v_m from public.raw_materials where id=p_material_id and active=true for update;
 if not found then raise exception 'Bahan tidak ditemukan atau nonaktif'; end if;
 v_delta:=case when p_type in ('purchase','adjustment_in') then p_quantity when p_type='opname' then p_quantity-v_m.stock_quantity else -p_quantity end;
 if v_delta=0 then raise exception 'Stok opname tidak mengubah jumlah stok'; end if;
 v_after:=v_m.stock_quantity+v_delta;
 if v_after<0 then raise exception 'Stok tidak mencukupi'; end if;
 update public.raw_materials set stock_quantity=v_after,purchase_price=case when p_type='purchase' and p_purchase_price is not null then p_purchase_price / p_quantity else purchase_price end,purchase_quantity=case when p_type='purchase' then p_quantity else purchase_quantity end,updated_at=now() where id=p_material_id;
 insert into public.stock_movements(raw_material_id,movement_type,quantity_delta,stock_before,stock_after,unit,unit_cost_snapshot,reason,created_by) values(p_material_id,p_type,v_delta,v_m.stock_quantity,v_after,v_m.base_unit,case when p_type='purchase' then p_purchase_price else null end,nullif(trim(p_reason),''),v_uid) returning id into v_id;
 insert into public.audit_logs(actor_id,action,entity_table,entity_id,before_data,after_data) values(v_uid,'inventory_stock_move','raw_materials',p_material_id::text,jsonb_build_object('stock',v_m.stock_quantity),jsonb_build_object('stock',v_after,'type',p_type,'quantity_delta',v_delta,'movement_id',v_id));
 return jsonb_build_object('movement_id',v_id,'stock_before',v_m.stock_quantity,'stock_after',v_after,'quantity_delta',v_delta);
end; $$;

create or replace function public.orion_inventory_save_recipe(p_product_key text,p_product_name text,p_items jsonb,p_activate boolean default false)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_uid uuid:=public.orion_inventory_require_manager(); v_id uuid; v_version integer; v_item jsonb; v_unit text; v_base text;
begin
 if nullif(trim(p_product_key),'') is null or nullif(trim(p_product_name),'') is null then raise exception 'Pilih menu yang valid'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'Resep harus memiliki minimal satu bahan'; end if;
 select coalesce(max(version),0)+1 into v_version from public.recipes where product_key=p_product_key;
 insert into public.recipes(product_key,product_name_snapshot,version,active,created_by) values(p_product_key,p_product_name,v_version,false,v_uid) returning id into v_id;
 for v_item in select * from jsonb_array_elements(p_items) loop
  v_unit:=v_item->>'unit';
  select base_unit into v_base from public.raw_materials where id=(v_item->>'raw_material_id')::uuid and active=true;
  if v_base is null then raise exception 'Bahan resep tidak ditemukan atau nonaktif'; end if;
  if v_unit<>v_base then raise exception 'Satuan resep harus sama dengan satuan dasar bahan (%)',v_base; end if;
  if coalesce((v_item->>'quantity')::numeric,0)<=0 then raise exception 'Takaran bahan harus lebih dari nol'; end if;
  insert into public.recipe_items(recipe_id,raw_material_id,quantity,unit) values(v_id,(v_item->>'raw_material_id')::uuid,(v_item->>'quantity')::numeric,v_unit);
 end loop;
 if p_activate then
  update public.recipes set active=false where product_key=p_product_key and id<>v_id and active=true;
  update public.recipes set active=true,effective_from=now() where id=v_id;
 end if;
 insert into public.audit_logs(actor_id,action,entity_table,entity_id,after_data) values(v_uid,'inventory_recipe_save','recipes',v_id::text,jsonb_build_object('product_key',p_product_key,'version',v_version,'active',p_activate,'items',p_items));
 return v_id;
end; $$;

revoke all on function public.orion_inventory_require_manager() from public,anon;
revoke all on function public.orion_inventory_list() from public,anon;
revoke all on function public.orion_inventory_save_material(uuid,text,text,text,numeric,text) from public,anon;
revoke all on function public.orion_inventory_stock_move(uuid,text,numeric,text,numeric) from public,anon;
revoke all on function public.orion_inventory_save_recipe(text,text,jsonb,boolean) from public,anon;
grant execute on function public.orion_inventory_require_manager() to authenticated;
grant execute on function public.orion_inventory_list() to authenticated;
grant execute on function public.orion_inventory_save_material(uuid,text,text,text,numeric,text) to authenticated;
grant execute on function public.orion_inventory_stock_move(uuid,text,numeric,text,numeric) to authenticated;
grant execute on function public.orion_inventory_save_recipe(text,text,jsonb,boolean) to authenticated;
commit;
