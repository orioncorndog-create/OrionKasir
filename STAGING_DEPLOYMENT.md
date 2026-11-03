# OR!ON CORNDOG POS PRO v2.36 — Staging Deployment

- Supabase staging: `varissdevhgyeqsijpli` only.
- Production Supabase and `https://orion-corndog.pages.dev` must remain untouched.

Before deployment: set the staging publishable key (`sb_publishable_...`) in `js/supabase-config.js`; configure staging Site URL/Redirect URLs to the Preview URL; verify staging Reset Password email template and SMTP; inspect the exact SQL signatures and JSON contract of `pos_get_state` and `pos_save_state`. Current code calls `pos_get_state()` and `pos_save_state(p_payload: data)`.

Upload this folder to a separate Cloudflare Pages staging/Preview destination only. Test with existing staging owner/manager accounts.
