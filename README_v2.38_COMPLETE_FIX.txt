OR!ON CORNDOG POS PRO v2.38 — COMPLETE FIX

Berbasis langsung pada source v2.37 AUTO LOGIN FIX. Seluruh data seed, menu, transaksi, dan struktur PWA dipertahankan.

PERUBAHAN
1. Hak akses Manager: laporan, keuangan, riwayat, menu/kategori, promo, stok, absensi, dan operasional outlet. Pembuatan akun, pengaturan role, hak akses, dan konfigurasi payment gateway tetap Owner-only.
2. Lapisan backend Supabase: RPC pos_get_state / pos_save_state memeriksa role aktif di pos_profiles. Manager tidak dapat menulis users/role, permissions, atau paymentGateway. Kasir hanya dapat menyimpan sales dan attendance melalui RPC. Akses langsung tabel pos_state dicabut oleh migrasi.
3. Login tetap memulihkan sesi Supabase tersimpan sebelum menampilkan login. Logout tetap memanggil signOut.
4. Keranjang mobile: bottom sheet dipertahankan; area katalog diberi ruang bawah tambahan dan isi keranjang dapat discroll saat sheet diperluas.
5. Pembayaran: Tunai selalu tersedia. QRIS Dinamis dan dompet digital hanya aktif bila status gateway connected, integrationVerified=true, dan metode wallet terdaftar. Menyimpan konfigurasi tidak mengaktifkan integrasi. QRIS manual/transfer/kartu tetap mengikuti pilihan Owner.
6. Foto menu: validasi gambar maksimal 12 MB, kompresi WebP (JPEG fallback), sisi maksimum 1.400 px, status upload, upload Supabase Storage ke bucket orion-menu-images, URL publik hanya disimpan setelah upload berhasil. Pada mode lokal gambar disimpan sebagai data URL terkompresi. Foto lama tidak diganti bila upload gagal.
7. Pull-to-refresh mobile menjadi soft refresh; tidak reload dokumen, menjaga keranjang, pencarian, halaman aktif, dan sesi.
8. Cache PWA dinaikkan ke v2.38 agar file baru diambil setelah deployment.

WAJIB SEBELUM DEPLOY CLOUD
- Backup database Supabase.
- Jalankan schema.sql lengkap pada project baru, ATAU jalankan schema_v2.38_complete_fix.sql pada project yang sudah memakai schema sebelumnya. Jangan jalankan dua-duanya berturut-turut tanpa kebutuhan.
- Pastikan semua Owner/Manager/Kasir sudah mempunyai row aktif di public.pos_profiles dengan role yang benar. Owner pertama perlu ditetapkan melalui SQL Editor seperti contoh pada schema.sql.
- Upload seluruh folder hasil ZIP ke hosting dengan HTTPS.
- Konfigurasi Supabase Auth redirect URL sesuai domain aplikasi.
- Gateway QRIS/ewallet belum diintegrasikan; statusnya sengaja tetap tidak aktif sampai backend provider benar-benar diimplementasikan dan diuji. Tidak ada klaim transaksi gateway aktif.
- Foto AI otomatis untuk produk tanpa gambar tidak disertakan karena source ini tidak mempunyai layanan image-generation/API server. Produk tetap dapat memakai ikon/placeholder dan Owner/Manager dapat mengunggah foto menu.

PEMERIKSAAN YANG DILAKUKAN
- Arsip sumber dapat dibaca dan diuji integritasnya sebelum ekstraksi.
- Pemeriksaan sintaks JavaScript dilakukan dengan Node.js --check untuk app.js, db.js, dan service-worker.js.
- Pemeriksaan ZIP hasil dan keberadaan seluruh file dilakukan setelah pengemasan.
- Tidak ada koneksi ke project Supabase pengguna dalam sesi ini; migrasi SQL, autentikasi nyata, RLS live, Storage, pembayaran gateway, dan perilaku perangkat Android harus diuji pada project/hosting pengguna sebelum operasional.
