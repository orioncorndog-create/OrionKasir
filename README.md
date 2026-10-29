# OR!ON CORNDOG POS Pro v2.21 — Responsive Dashboard

## Revisi layout v2.21
- Layout utama dan konten memakai lebar fleksibel penuh, tanpa pembatas max-width yang menyempitkan halaman.
- Pada tablet/iPad (lebar 768 px ke atas), sidebar navigasi tampil permanen di kiri dan bukan edge panel.
- Pada layar 1024 px ke atas, halaman kasir menggunakan dashboard dua kolom (katalog dan keranjang).
- Kartu metrik dan grid produk menyesuaikan ukuran layar; tabel tetap dapat digeser di dalam pembungkusnya tanpa membuat seluruh halaman melebar.
- Pada HP, navigasi tetap memakai edge panel dan grid produk tetap dua kolom.

## Deploy
Unggah seluruh isi folder hasil ekstrak ke hosting Netlify untuk menggantikan versi sebelumnya. Service worker dan query asset diperbarui ke v2.21. Setelah deploy, muat ulang situs atau bersihkan cache bila masih tampil versi lama.

## Supabase
Jika memakai sinkronisasi online, isi `js/supabase-config.js` dengan Project URL dan publishable/anon key Supabase, lalu jalankan `schema.sql` pada SQL Editor. Jangan gunakan service_role key di browser.
