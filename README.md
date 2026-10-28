# OR!ON CORNDOG POS Pro v2.1 — UI & receipt fixes

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

## Perbaikan v2.1
- Logo OR!ON CORNDOG ditampilkan di header, halaman login, dan struk.
- Form tambah/edit menu mendukung unggah foto dari perangkat; gambar dikompres sebelum disimpan.
- Foto menu ditampilkan pada kartu kasir dan tabel menu.
- Navigasi HP dibuat horizontal, dapat digeser, dan tidak memaksa semua tab masuk ke layar.
- CSS cetak struk diarahkan ke format thermal 58 mm. Tetap lakukan uji cetak pada perangkat/printer yang digunakan.
- Foto disimpan sebagai data gambar pada record menu; hindari gambar berukuran sangat besar karena mode lokal memakai penyimpanan browser.

## Perbaikan v2.2
- Kartu menu kini hanya memakai foto produk. Jika gambar belum ditambahkan, area gambar dibiarkan kosong tanpa emoji atau ikon.
- Foto produk memakai object-fit: contain agar tidak terpotong; rasio dan area gambar dibuat konsisten.
- Navigasi responsif diperbaiki: pada HP tampil penuh dalam grid 2/3 kolom, bukan menimpa judul halaman atau hanya terlihat setengah.
- Tombol smart sidebar untuk menyembunyikan/menampilkan navigasi. Pada desktop, navigasi dapat diciutkan menjadi ikon.
- Header logo disesuaikan agar tidak terpotong dan seluruh halaman menggunakan tata letak responsif yang lebih rapi.


## OR!ON POS Pro v2.4 — branding, mobile checkout, quantity controls
- Logo PNG transparan penuh 4K dipasang pada login, header, dan struk tanpa blend mode atau latar bawaan; rasio logo dipertahankan agar kata CORNDOG dan garis bawah tidak terpotong.
- Login dan header menggunakan dimensi responsif dan object-fit: contain.
- Setiap kartu produk memiliki kontrol qty minus/angka/plus; jumlah tersinkron dengan keranjang, batas stok tetap berlaku.
- Keranjang/pembayaran menjadi floating checkout sheet pada layar kecil saat ada item; rincian item dapat digulir dan metode pembayaran, uang diterima, kembalian, serta tombol bayar tetap berada dalam panel.
- Penyegaran gaya visual dengan warna wine, orange hangat, ivory, radius lembut, dan bayangan ringan.
- Uji langsung di perangkat dan printer tetap diperlukan sebelum operasional.

## v2.5 — perbaikan interaksi kasir
- Kartu menu dapat diketuk untuk menambahkan satu item; tombol +/− tetap mengubah qty secara langsung.
- Bottom sheet pembayaran di HP muncul saat item pertama ditambahkan. Tampilan tertutup hanya menampilkan jumlah item dan total, lalu dapat dibuka untuk mengatur pembayaran tanpa scroll panjang ke bawah.
- Panel pembayaran tetap menggunakan validasi transaksi, stok, metode pembayaran, uang diterima, dan kembalian yang sudah ada.
- Edge panel navigasi kiri dipersempit; warna dan bayangan diperhalus.
- Perbarui cache/service worker ke v2.5. Uji ulang pada perangkat sebelum digunakan langsung.
