OR!ON CORNDOG POS - AI/OCR MENU IMPORT v2.35

FITUR BARU
- Impor satu atau beberapa screenshot/foto laporan HPP.
- OCR dijalankan di browser melalui Tesseract.js yang dimuat dari CDN saat tombol Baca gambar digunakan. Koneksi internet diperlukan saat pertama kali memuat mesin OCR.
- Hasil pembacaan dapat diperiksa dan diedit sebelum disimpan.
- Nama menu yang cocok dengan data lama ditandai sebagai duplikat.
- Untuk setiap duplikat, pengguna memilih Lewati menu lama (default) atau Perbarui harga & HPP.
- Impor baru tidak mengubah transaksi, pengaturan, stok, kategori, atau menu lama. Stok menu baru diisi 0 secara default kecuali diedit sebelum impor.
- Konfirmasi akhir wajib dilakukan sebelum perubahan disimpan.

PENTING
- OCR bukan pembacaan sempurna. Selalu cek harga/HPP/kategori sebelum impor.
- Data database dan konfigurasi Supabase tidak diubah oleh patch ini. Tetap lakukan backup sebelum deploy.
- Ini menggunakan OCR lokal di browser, bukan layanan AI generatif; struktur tabel gambar yang kompleks bisa membutuhkan koreksi manual.
- Kode ini belum diuji terhadap hosting/database produksi milik pengguna.
