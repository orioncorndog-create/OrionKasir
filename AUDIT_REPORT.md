# OR!ON CORNDOG POS — Audit Source v2.40

## Source
- ZIP: `ORION_CORNDOG_POS_PRO_v2.40_SCROLL_FIX.zip`
- Extracted successfully; 25 ZIP entries.
- Existing application is a vanilla HTML/CSS/JavaScript PWA.
- Main application logic: `js/app.js`; local persistence: `js/db.js`.
- Supabase client loaded from jsDelivr and configured in `js/supabase-config.js`.
- Existing SQL files: `schema.sql`, `schema_v2.38_complete_fix.sql`.

## Existing screens
Kasir, Menu & Kategori, Promo, Stok (currently product-sales ranking, not raw-material inventory),
Laporan, Keuangan, Absensi, Riwayat Penjualan, Pengaturan.

## Existing backend
Tables found in the provided schema:
- `public.pos_state` (single JSONB application snapshot)
- `public.pos_profiles`
- `public.pos_pending_roles`

RPC functions found:
- `pos_get_state()`
- `pos_save_state(jsonb)`
- `pos_owner_set_role(uuid,text)`
- `pos_current_role()`

The current app reads/writes its application snapshot through `pos_get_state` and `pos_save_state`.
The browser code contains local-first transaction persistence; `checkout()` adds a sale to local data,
then asynchronously calls the snapshot synchronization path. This is not a server-atomic sale flow.

## Existing feature findings
- Supabase email/password and phone/password auth code exists.
- Role labels and some page-level UI restrictions exist.
- Menu, categories, menu images, promos, cart, checkout, payment methods and delivery fee exist.
- Receipt image sharing via Web Share/download fallback exists.
- Sales history, reports, basic finance entries, attendance and CSV/JSON export exist.
- Printer settings and Web Bluetooth/WebUSB capability paths exist, but actual device compatibility is not verified.
- PWA manifest and service worker exist.

## Important gaps against Professional System target
1. No normalized cashier shift, shift member, cash drawer, or reconciliation tables.
2. `shiftKey` is a grouping key, not a full shift lifecycle/reconciliation system.
3. Stock is attached to menu products; no raw material master, BOM, recipe revision or ingredient movements.
4. Checkout has no idempotency key and no atomic server-side payment/inventory transaction.
5. Role restrictions are partly UI/snapshot-based; granular per-operation RBAC is not complete.
6. No append-only audit log found in the supplied schema.
7. Finance data is currently stored in the legacy JSON snapshot, not a normalized expense ledger.
8. Backup code downloads local JSON; no verified Supabase scheduled backup/restore integration exists.
9. Printer settings are not proof of successful ESC/POS printing or cash drawer operation.

## Validation performed
- ZIP extraction: passed.
- JavaScript syntax checks (`node --check`) for `js/app.js`, `js/db.js`,
  `js/supabase-config.js`, and `service-worker.js`: passed.
- SQL was statically inspected. It was not executed against the user's Supabase project.
- No live Supabase, RLS, browser transaction, printer, USB/Bluetooth, or physical cash drawer test was performed.

## Phase 2 migration included
`migration_professional_phase2.sql` is an additive foundation migration for new normalized tables.
It does not drop or rewrite the existing `pos_state` table or existing business data.
New tables are RLS-enabled and direct browser grants are revoked pending scoped RPC implementation.

**Important:** this foundation migration is not a completed feature release. The new tables are not
yet connected to the existing cashier UI or checkout flow. Do not apply it to production until a
database backup has been taken and the SQL has been reviewed/tested on a staging Supabase project.

## Next implementation sequence
1. Add and test scoped RPCs for shift open/join/cash movements/reconciliation.
2. Add shift screens and gate checkout on an active shift.
3. Add recipe/material management and stock movement RPCs.
4. Replace local-first checkout with an idempotent atomic transaction RPC while preserving legacy sales.
5. Complete granular RBAC/RLS and audit events.
6. Add financial reports from immutable transaction/HPP snapshots.
7. Complete printer bridge/device tests, backup documentation and regression tests.


## Phase 3 implementation status — Shift backend

Added `migration_phase3_shift_rpc.sql` with scoped RPCs for opening individual/shared shifts,
joining/leaving shared drawers, cash movements, drawer creation, active-shift lookup, and
cash reconciliation/closure. All operations derive identity and role from the authenticated
Supabase session and append audit events.

Static review only. SQL has not been executed against a PostgreSQL/Supabase instance.
The current v2.40 checkout is not yet connected to `payment_records`, so the reconciliation
RPC intentionally reports only normalized payment records and must not be treated as a
complete live shift total until the transaction engine integration is completed.
The application UI and checkout gate are not yet connected to these RPCs.
