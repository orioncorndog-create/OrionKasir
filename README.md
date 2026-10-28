# OR!ON CORNDOG POS Pro v2

## Fitur yang tersedia
- Login demo lokal.
- Menu dan kategori: tambah, edit, aktif/nonaktif.
- Promo diskon per menu: persentase atau nominal, periode tanggal.
- Stok: pengurangan otomatis saat checkout, penyesuaian manual, peringatan stok menipis/habis.
- Kasir: tunai, QRIS, transfer, lainnya; diskon dihitung otomatis.
- HPP dan laba kotor terlihat pada layar internal kasir/laporan, **tidak dicetak pada struk pelanggan**.
- Struk pelanggan: nama outlet, item, subtotal, diskon, total, pembayaran, uang diterima, kembalian.
- Laporan, menu terlaris, metode pembayaran, ekspor CSV.
- Keuangan manual (pemasukan/pengeluaran), absensi, riwayat penjualan, tutup/buka outlet.
- Pengaturan outlet, ekspor/pulihkan backup JSON.
- PWA dapat dipasang pada layar utama.

## Jalankan mode lokal
1. Ekstrak ZIP.
2. Upload **isi folder** ini ke Netlify/Vercel/static hosting, sehingga `index.html`, `css/`, `js/`, `icons/`, `manifest.json` ada di root deploy.
3. Buka URL. Login demo:
   - Email: `admin@orion.local`
   - Password: `orion123`
4. Mode lokal menyimpan data di browser/perangkat yang dipakai. Jangan gunakan mode lokal untuk sinkronisasi antar-HP.

## Aktifkan login dan sinkronisasi real-time antar-HP (Supabase)
Backend tidak bisa dibuat aktif hanya dengan upload ZIP: Anda perlu membuat proyek Supabase sendiri dan memasukkan kredensial proyek.

1. Buat proyek di Supabase.
2. Buka **Project Settings → API** dan salin Project URL serta anon/public key.
3. Edit `js/supabase-config.js`:
   ```js
   window.ORION_SUPABASE_URL = "https://PROJECT-ANDA.supabase.co";
   window.ORION_SUPABASE_ANON_KEY = "ANON_PUBLIC_KEY_ANDA";
   ```
   Jangan masukkan `service_role` key ke aplikasi/browser.
4. Di Supabase **SQL Editor**, jalankan isi `schema.sql`.
5. Di **Authentication → Users**, buat akun untuk admin dan kasir. Login memakai email/password yang dibuat di sana.
6. Deploy ulang seluruh isi folder ke hosting, buka aplikasi pada masing-masing HP dan login dengan akun yang sama/profil yang diizinkan.
7. Gunakan tombol **Sinkronkan sekarang** untuk mengirim snapshot awal. Perubahan yang tersimpan pada tabel `pos_state` memicu pembaruan Realtime pada perangkat lain.

### Penting untuk pemakaian bisnis
- Skema Supabase pada paket ini adalah **prototipe snapshot** yang cocok untuk menguji sinkronisasi. Beberapa perangkat yang mengubah data secara bersamaan bisa menimpa perubahan satu sama lain; jangan jadikan ini satu-satunya catatan akuntansi produksi.
- Kebijakan SQL contoh mengizinkan semua pengguna terautentikasi membaca/menulis snapshot. Untuk operasional sungguhan, atur role admin/kasir, pembatasan per outlet, audit log, backup, dan validasi server-side sebelum dipakai.
- Aplikasi web ini bukan layanan backend yang sudah di-host oleh pembuat ZIP; sinkronisasi real-time baru aktif setelah konfigurasi Supabase, schema, dan akun selesai.
- Login demo hanya untuk mode lokal dan bukan login aman untuk internet publik.

## Isi folder
- `index.html` — layar login dan halaman aplikasi
- `css/styles.css` — tampilan responsif
- `js/db.js` — data awal dan penyimpanan lokal
- `js/app.js` — logika POS dan modul
- `js/supabase-config.js` — konfigurasi backend yang perlu diisi
- `schema.sql` — tabel dan kebijakan dasar Supabase
- `manifest.json`, `service-worker.js`, `icons/` — dukungan PWA
