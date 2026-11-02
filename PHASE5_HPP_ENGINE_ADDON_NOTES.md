# OR!ON CORNDOG POS PRO — HPP Engine Add-on

This is a proposed additive database add-on, not yet deployed or live-tested.

## What it does
- Adds `raw_materials.stock_tracking_enabled`, default `false` for all existing materials. This avoids interpreting legacy/default `stock_quantity = 0` as a confirmed physical count.
- Adds `orion_inventory_update_material_price(...)`, which updates the latest purchase cost per base unit and supplier without changing stock quantity or creating a stock movement.
- Adds `orion_inventory_hpp_report()`, a read-only report of active BOM HPP calculated from `recipe_items.quantity * raw_materials.purchase_price`.
- Writes audit records for price updates.

## Unit conversion example
For flour bought as 25 kg at Rp270,000, convert to the base unit first:
- `p_quantity_base = 25000` (grams)
- `p_total_cost = 270000`
- calculated unit cost = Rp10.8 per gram.

For an ingredient measured in ml or pcs, pass the corresponding base-unit quantity.

## Safety boundaries
- Does not update `pos_state`, products, product.hpp, sales, payment records, shifts, or historical transactions.
- Does not migrate product stock into ingredient stock.
- Does not create materials or recipes from the HPP image automatically.
- Does not activate recipes or deduct stock at checkout.
- Existing Phase 2–5 migrations must not be rerun.

## Important implementation status
This SQL add-on is prepared but not executed. The current app UI still needs a reviewed frontend patch to expose the price-only update and display the HPP report. Test this SQL on a staging Supabase project and inspect RPC results before production use.
