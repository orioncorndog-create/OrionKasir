# OR!ON CORNDOG POS Pro v2.26

## Perbaikan
- Menu tiga titik pada halaman kasir menggunakan popover fixed dengan z-index tinggi, sehingga tidak tertutup kartu HPP atau kartu statistik lain.
- Pembayaran memiliki opsi ongkir delivery yang dapat diaktifkan/nonaktifkan per transaksi. Saat aktif, kasir dapat memasukkan biaya ongkir; nominal otomatis ditambahkan ke total, validasi uang tunai/kembalian, dan disimpan pada transaksi.
- Opsi delivery dan biaya direset setelah transaksi berhasil agar tidak terbawa ke pesanan berikutnya.

## Instalasi
Unggah seluruh isi folder ini ke hosting menggantikan versi sebelumnya. Jika cache lama masih tampil, refresh paksa atau bersihkan cache aplikasi/PWA.

Catatan: uji langsung pada perangkat dan hosting produksi tetap disarankan sebelum dipakai untuk transaksi nyata.


## Patch v2.26
- Dropdown pengaturan kasir otomatis tertutup setelah opsi dipilih dan saat klik di luar menu.
- Logo OR!ON CORNDOG ditempatkan statis di atas label TRANSAKSI dan judul Kasir.
- Header serta dropdown tidak menggunakan posisi fixed/sticky; keduanya mengikuti alur halaman saat scroll.
