# Phase 3 — Shift Management Backend

## Included
- Individual shift opening with opening cash.
- Shared cash drawer opening, cashier membership, and leave.
- Owner/Manager cash drawer creation.
- Cash in, cash out, and cash drop records.
- Shift closing and cash reconciliation.
- Server-side user/role checks and audit events.

## Install order
1. Back up the Supabase project.
2. Apply `migration_professional_phase2.sql` on a staging project.
3. Verify Phase 2 tables exist and RLS is enabled.
4. Apply `migration_phase3_shift_rpc.sql`.
5. Test with separate Owner, Manager, and Cashier accounts.
6. Do not apply to production until the staging tests pass.

## Important limitations
- This is the shift RPC/backend phase, not a completed user-facing shift module.
- The legacy checkout is not yet writing `payment_records`; shift sales reconciliation is therefore incomplete until the next transaction-engine phase.
- SQL was statically reviewed only; no live Supabase execution was performed.
- The existing app source and historical data are retained unchanged.
