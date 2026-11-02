# OR!ON CORNDOG POS — Patch login/sinkronisasi RPC v2.38

## Tujuan
Memperbaiki ketidakcocokan antara frontend lama yang mengakses `public.pos_state` secara langsung dan migrasi keamanan v2.38 yang mencabut akses langsung `anon/authenticated`, serta menyediakan RPC `pos_get_state()` dan `pos_save_state(new_payload jsonb)`.

## Perubahan
- `pullRemote()` membaca snapshot melalui `supabase.rpc("pos_get_state")`.
- `pushRemote()` menyimpan snapshot melalui `supabase.rpc("pos_save_state", {new_payload: snapshot})`.
- Cache Service Worker dinaikkan agar perangkat tidak terus memakai JavaScript lama.
- Tidak ada perubahan pada data lokal, transaksi, akun, stok, atau database.

## Prasyarat penting
Patch ini hanya dapat bekerja jika fungsi `public.pos_get_state()` dan `public.pos_save_state(jsonb)` dari `schema_v2.38_complete_fix.sql` memang sudah terpasang di Supabase, dan profil pengguna aktif tersedia di `pos_profiles`.

Jika RPC belum ada, jangan membuka akses langsung `pos_state` sebagai jalan pintas. Terapkan migrasi yang telah diaudit setelah backup dan pemeriksaan schema live.

## Pemeriksaan
- `node --check js/app.js`: lulus.
- `node --check service-worker.js`: lulus.
- Belum diuji pada Supabase live, browser Android, atau Netlify.
