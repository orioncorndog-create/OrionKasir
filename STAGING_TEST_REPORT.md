# Staging Test Report — v2.36
Date: 2026-11-03

## Local checks
- Original ZIP integrity: PASS (17 entries, no unzip errors).
- Required files present: PASS.
- Password recovery UI and handlers implemented.
- Recovery callback (`type=recovery`) and `PASSWORD_RECOVERY` handler implemented.
- Password policy (8 chars + confirmation) and `updateUser({password})` implemented.
- Frontend config targets staging only; public key placeholder intentionally remains.
- Sync source now calls RPC functions `pos_get_state` and `pos_save_state`. Cloud writes are **fail-closed** while `ORION_RPC_CONTRACT_VERIFIED` is false pending SQL verification.

## Not run / blocked
- Supabase staging project introspection/RPC audit: connector returned permission denied for project access.
- Staging publishable key unavailable; app remains fail-closed/local while placeholder remains.
- Owner/manager sign-in, email delivery, callback round trip, actual password update: NOT RUN.
- RPC contract, RLS, and multi-user authorization: NOT VERIFIED.
- Cloudflare Pages Preview deploy: NOT RUN.

No Production project, configuration, database, users, migration, or site was changed.
