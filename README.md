# OR!ON CORNDOG POS & Margin App

Starter PWA kasir offline-first. Tampilan responsif untuk HP dan desktop.

## Fitur
- Grid menu, pencarian, filter kategori.
- Keranjang dengan tambah/kurangi kuantitas.
- Hitung omzet, HPP dan laba kotor otomatis.
- Pembayaran Tunai dan QRIS; hitung uang diterima/kembalian untuk tunai.
- Simpan riwayat transaksi ke localStorage.
- Ekspor riwayat ke CSV dan cetak struk.
- Service worker cache untuk penggunaan offline setelah kunjungan pertama.

## Jalankan lokal
Service worker membutuhkan HTTPS atau localhost. Cara mudah:
1. Ekstrak ZIP.
2. Jalankan server statis dari folder ini, misalnya `python -m http.server 8000`.
3. Buka `http://localhost:8000` di browser.

Jangan hanya membuka `index.html` dengan `file://` jika ingin menguji PWA/offline.

## Unggah ke PWABuilder
1. Unggah/deploy seluruh isi folder ini ke hosting HTTPS (mis. GitHub Pages, Netlify, atau hosting sendiri).
2. Buka PWABuilder dan masukkan URL HTTPS aplikasi.
3. Pastikan manifest dan service worker bisa diakses, lalu jalankan validasi.

## Ikon
Folder `icons/` berisi ikon PNG 192×192 dan 512×512 yang dibuat untuk starter ini.

## Penting tentang data
Harga jual dan HPP adalah data awal yang disediakan dalam permintaan. Menu yang belum tercantum dan HPP yang belum terverifikasi belum ditambahkan. Periksa ulang semua harga/HPP sebelum dipakai untuk pembukuan resmi. Laba yang ditampilkan adalah laba kotor sederhana (penjualan − HPP), belum mengurangi biaya operasional, kemasan, komisi platform, pajak, atau biaya QRIS.

Semua data transaksi tersimpan hanya di browser/perangkat yang dipakai. localStorage bukan database bersama dan data dapat hilang jika data situs dihapus. Ekspor CSV secara berkala. Skema SQL hanya contoh dan belum terhubung ke aplikasi.
