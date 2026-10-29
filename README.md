# OR!ON CORNDOG POS Pro v2.19 — Supabase Sign Up & Login

## Mengaktifkan akun dan sinkronisasi lintas perangkat
1. Buat proyek di https://supabase.com/ dan buka Project Settings → API (atau Connect). Salin **Project URL** dan **publishable/anon key**. Jangan pernah memasukkan `service_role` key ke aplikasi browser.
2. Edit `js/supabase-config.js`: isi `window.ORION_SUPABASE_URL` dan `window.ORION_SUPABASE_ANON_KEY` dengan nilai proyek milik Anda.
3. Buka SQL Editor di proyek Supabase, tempel seluruh isi `schema.sql`, lalu jalankan. Jika tabel sudah pernah dibuat dan perintah publication memunculkan error karena tabel sudah ada, periksa publication `supabase_realtime` dan pastikan `public.pos_state` sudah termasuk di dalamnya.
4. Di Authentication → URL Configuration, masukkan URL hosting aplikasi ke Site URL dan Redirect URLs. Untuk verifikasi email, atur SMTP/email sesuai kebutuhan; secara default Supabase dapat meminta pengguna mengonfirmasi email sebelum login.
5. Deploy seluruh isi folder ke hosting HTTPS. Buka URL yang sama di setiap HP. Tekan **Buat akun baru**, isi nama, email, dan password minimal 6 karakter. Setelah verifikasi email (jika diminta), login dengan akun itu.
6. Akun yang mendaftar otomatis ber-role `employee`. Untuk memberi hak owner, jalankan SQL berikut di SQL Editor dengan email pemilik yang benar:

```sql
update public.pos_profiles p
set role = 'owner', updated_at = now()
from auth.users u
where p.id = u.id and u.email = 'email-pemilik-anda@contoh.com';
```

## Penting
- Tanpa URL dan key Supabase, aplikasi tetap berada pada mode lokal; akun demo `admin@orion.local` / `orion123` hanya untuk demo lokal.
- Data baru tersinkron antar-HP yang memakai proyek Supabase yang sama. Data lokal lama tidak otomatis digabung ke cloud; ekspor cadangan dan lakukan migrasi dengan hati-hati.
- Schema prototipe ini memberi semua pengguna terautentikasi akses ke satu snapshot `pos_state`. Daftarkan hanya staf tepercaya. Untuk penggunaan publik/produksi multi-outlet, sebaiknya batasi pendaftaran dan terapkan kebijakan per outlet/role sebelum menyimpan data sensitif.
- Jangan membagikan `service_role` key. Hanya gunakan publishable/anon key di `js/supabase-config.js`.
