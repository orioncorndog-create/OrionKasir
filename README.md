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

## OR!ON POS Pro v2.7 — checkout layar penuh dan menu tambahan
- Tombol kuantitas pada kartu menu kini dapat menambahkan item dari qty 0, mengurangi sampai 0, dan tetap mengikuti batas stok.
- Menambahkan menu tambahan dari lembar HPP yang diberikan: 10 menu Sosis Bakar dan 8 menu Milky Series II. Migrasi hanya menambahkan nama menu yang belum ada; produk yang sudah tersimpan tidak ditimpa.
- Panel ringkas di HP hanya menampilkan jumlah item dan total nominal. Menambahkan item tidak otomatis membuka panel.
- Tombol ringkasan membuka layar pembayaran penuh dengan daftar produk, qty, hapus item, subtotal, diskon, total, metode pembayaran, nominal tunai, kembalian, serta estimasi HPP/laba internal.
- Sebelum menyimpan transaksi, aplikasi menampilkan ringkasan konfirmasi. Klik proses ganda diblokir selama proses berjalan; stok divalidasi sebelum disimpan dan kembalian hanya dihitung untuk tunai.
- Cache service worker dinaikkan ke v2.7 agar browser mengambil versi aset yang baru.
- Pemeriksaan sintaks JavaScript dan struktur ID dilakukan pada paket ini. Pengujian transaksi langsung di HP/Netlify dan sinkronisasi antar-perangkat tetap perlu dilakukan di lingkungan deployment Anda.


## Pembaruan v2.7
- Kategori kasir Sweet Mozzarella dan Savory Mozzarella dipisahkan dan diurutkan di awal daftar kategori.
- Produk dengan promo aktif ditampilkan dalam bagian Promo Aktif di atas daftar kategori, hanya jika ada promo yang sedang berlaku.
- Menu diurutkan berdasarkan jumlah terjual pada riwayat transaksi; tiga menu teratas per kategori yang memiliki penjualan diberi penanda jempol.
- Struk memiliki tombol Kirim WhatsApp yang menyusun teks rincian transaksi tanpa HPP dan laba kotor internal.
- Menu mozzarella tambahan yang belum ada akan dibuat nonaktif dengan harga/HPP/stok nol agar tidak ikut dijual sebelum datanya dilengkapi di halaman Menu.

## v2.10 — Struk gambar & role akun (catatan penting)
- Tombol WhatsApp mencoba membagikan file PNG struk melalui Web Share API jika browser/perangkat mendukung berbagi file. Jika tidak, PNG diunduh dan WhatsApp dibuka dengan teks singkat; kasir perlu melampirkan PNG secara manual. Ini bukan pengiriman otomatis tanpa tindakan pengguna.
- Login Supabase membaca role dari `public.pos_profiles`. Trigger SQL membuat akun baru sebagai `employee` secara default. Owner perlu menetapkan `owner` atau `manager` melalui SQL Editor setelah membuat akun di Supabase Authentication.
- Role pada UI membantu menyembunyikan halaman dan mencegah sebagian aksi. Namun tabel snapshot `pos_state` pada skema lama masih memberi akses tulis kepada seluruh pengguna terautentikasi. Karena data aplikasi tersimpan dalam satu JSON snapshot, pembatasan per-role belum aman di tingkat database. Jangan gunakan ini sebagai kontrol keamanan produksi sebelum data dinormalisasi dan RLS/operasi transaksi dibatasi, atau seluruh mutasi dipindahkan ke backend tepercaya.
- Jangan pernah memasukkan Supabase service-role/secret key ke JavaScript frontend. Pembuatan/invitasi akun dari dalam aplikasi memerlukan backend tepercaya (mis. Supabase Edge Function) yang memvalidasi sesi owner; v2.10 belum menyediakan endpoint tersebut.
- Setelah menjalankan SQL, buat user di Supabase Authentication. Role default adalah employee. Contoh untuk menaikkan role: lihat komentar `update public.pos_profiles` di bagian akhir `schema.sql`.


### v2.10 — Penyempurnaan kasir mobile
- Bottom sheet pesanan sekarang benar-benar disembunyikan saat keranjang kosong, dan muncul setelah menu ditambahkan.
- Ketuk panel pesanan atau swipe ke atas pada handle panel untuk membuka layar pembayaran.
- Pembayaran tunai menyediakan tombol **Uang pas**, **Rp20.000**, **Rp50.000**, dan **Rp100.000**. Tombol Uang pas mengisi nominal persis sesuai total transaksi; kembalian dan validasi pembayaran diperbarui otomatis.
- Pemeriksaan yang dilakukan: sintaks JavaScript dan integritas arsip ZIP. Perilaku swipe dan tombol berbagi tetap perlu diuji pada perangkat/browser target.


## Pembaruan v2.11 — antarmuka kasir mobile
- Tulisan stok di kartu menu kasir disembunyikan agar katalog lebih ringkas; kontrol stok dan validasi stok tetap aktif di sistem.
- Bottom sheet pesanan mendukung geser ke atas untuk memperluas rincian pesanan dan geser ke bawah untuk meringkasnya. Ketuk header sheet tetap membuka layar pembayaran.
- Header kasir dan logo outlet mengecil saat halaman digulir di layar mobile.
- Tombol **＋ Gambar** pada header kasir memungkinkan pemilihan gambar latar. Gambar diperkecil/dikompresi dan disimpan bersama pengaturan lokal aplikasi.
