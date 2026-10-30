OR!ON CORNDOG POS PRO v2.39 — AI PRODUCT IMAGE INTEGRATION

VERSI INI
- Dibangun dari arsip ORION_CORNDOG_POS_PRO_v2.38_COMPLETE_FIX.
- Menambahkan tombol Buat Foto AI / Ganti Foto AI pada halaman Menu.
- Tombol hanya muncul untuk Owner dan Manager yang memiliki izin menu.
- Aplikasi memanggil Supabase Edge Function bernama generate-product-image melalui sesi login Supabase.
- Setelah berhasil, URL gambar AI disimpan ke produk dan langsung dirender di katalog serta layar kasir.
- Konfirmasi ditampilkan sebelum foto yang sudah ada diganti.
- Cache PWA dinaikkan ke v2.39.

YANG SUDAH HARUS ADA DI SUPABASE
1. Migrasi SQL v2.38 sudah pernah berhasil dijalankan. Jangan jalankan ulang tanpa kebutuhan.
2. Bucket publik orion-menu-images tersedia dengan kebijakan Storage Owner/Manager dari migrasi v2.38.
3. Edge Function generate-product-image sudah dibuat dan berhasil di-deploy.
4. Secret OPENAI_API_KEY sudah disimpan di Edge Functions > Secrets. Jangan masukkan API key ke file browser atau membagikannya.
5. Pengaturan Verify JWT with legacy secret pada fungsi dimatikan (OFF), karena fungsi melakukan validasi token pengguna melalui Supabase Auth di dalam kode.
6. Project URL dan publishable/anon key pada js/supabase-config.js harus menunjuk ke project Supabase yang sama.

CARA MEMASANG
1. Backup folder aplikasi/hosting saat ini.
2. Ekstrak seluruh isi ZIP v2.39.
3. Upload/ganti seluruh file dan folder aplikasi pada hosting HTTPS dengan struktur folder yang sama. Jangan hanya mengganti app.js.
4. Buka ulang aplikasi, logout lalu login kembali jika perlu. Jika masih menampilkan versi lama, tutup PWA/browser sepenuhnya lalu buka kembali agar service worker v2.39 aktif.
5. Login menggunakan akun Owner atau Manager aktif.
6. Buka halaman Menu. Produk tanpa foto memiliki tombol Buat Foto AI; produk yang sudah memiliki foto memiliki tombol Ganti Foto AI.
7. Klik tombol dan tunggu proses pembuatan selesai. Jangan menutup halaman selama proses berjalan.
8. Periksa katalog kasir dan pastikan foto muncul. Di Supabase Edge Functions > Logs, invocation akan terlihat setelah fungsi dipanggil.

PENTING
- Setiap pembuatan/penggantian foto memanggil OpenAI Images API dan dapat menimbulkan biaya sesuai akun/API usage OpenAI. Gunakan seperlunya.
- Fungsi hanya dapat dipakai saat aplikasi online dan sesi Supabase masih aktif.
- Kasir tidak melihat tombol AI. Owner/Manager tetap harus memiliki profil aktif pada pos_profiles.
- Foto pengganti baru menggantikan URL pada produk setelah proses berhasil. Jika proses gagal, foto lama tetap digunakan.
- Foto lama yang URL-nya digantikan tidak otomatis dihapus dari Storage; hapus secara manual bila memang ingin membersihkan file lama.
- Tidak ada perubahan pada migrasi SQL v2.38 yang diperlukan untuk integrasi ini.
- File ZIP berisi aplikasi frontend. Edge Function tetap berada di Supabase dan tidak perlu ditempel ulang selama sudah berhasil di-deploy.

PEMERIKSAAN
- JavaScript app.js dan service-worker.js diperiksa dengan node --check.
- Arsip hasil diperiksa setelah pengemasan.
- Integrasi belum dapat diuji langsung terhadap akun Supabase/OpenAI pengguna dari lingkungan ini. Lakukan satu uji foto pada produk contoh setelah upload hosting. Jika gagal, kirim pesan error dari toast aplikasi atau Logs Edge Function; jangan membagikan nilai OPENAI_API_KEY.
