OR!ON CORNDOG POS PRO — v2.37 AUTO LOGIN FIX

Perubahan:
- Menambahkan splash/boot screen yang tampil saat aplikasi mulai.
- Menyembunyikan halaman login pada HTML awal agar tidak muncul sebelum sesi diperiksa.
- Memulihkan sesi lokal atau Supabase sebelum menampilkan dashboard/login.
- Menampilkan login hanya jika sesi tidak tersedia atau pemulihan autentikasi gagal.
- Memastikan dashboard menutup splash setelah sesi berhasil dipulihkan.
- Mempertahankan alur logout yang sudah ada.
- Memperbarui cache Service Worker menjadi orion-pos-v2.37 dan memperbarui URL versi CSS/JavaScript.
- Mendaftarkan Service Worker dengan updateViaCache:none agar pemeriksaan pembaruan script tidak tertahan cache HTTP.

Catatan pemeriksaan:
- File JavaScript diperiksa dengan Node.js --check.
- Arsip ZIP diperiksa integritasnya setelah dibuat.
- Perilaku runtime tetap perlu dikonfirmasi pada perangkat Android/PWA yang terpasang dan pada proyek Supabase milik pengguna.
