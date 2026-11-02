# OR!ON CORNDOG POS PRO — Phase 3–5 Frontend Restoration (Safe Stage)

## Isi paket
- Frontend Phase 3/4: halaman Shift Kasir, individual/shared cash drawer, cash movement, close/reconciliation UI.
- Frontend Phase 5: halaman Inventaris & Resep dipulihkan.
- Login/snapshot menggunakan RPC `pos_get_state()` dan `pos_save_state()`; tidak melakukan akses langsung ke `pos_state`.
- Snapshot writes diserialisasi melalui antrean promise untuk mencegah request tumpang tindih dari satu tab.
- Service worker cache version dibump untuk mengurangi risiko aset lama tertahan.

## Pengamanan penting
- Modul Inventaris ditampilkan tetapi operasi tulis dinonaktifkan sementara.
- Alasannya: RPC legacy `orion_inventory_*` menulis ke `raw_materials`/`stock_movements`, sedangkan sistem HPP FIFO yang ditetapkan menggunakan tabel `hpp_*`. Mengaktifkannya sebelum adapter tervalidasi dapat membuat dua sumber stok.
- Tidak ada migrasi SQL yang otomatis dijalankan.
- Tidak ada transaksi/stok lama yang dihapus atau dimodifikasi oleh proses build ini.

## Belum boleh dianggap selesai/siap produksi
- Belum ada koneksi langsung ke Supabase live untuk memeriksa definisi RPC Phase 3, RLS, constraint, dan schema HPP.
- Shift UI memanggil RPC `orion_shift_*`; ketersediaan dan signature di database live harus diuji sebelum operasi shift nyata.
- Pembelian HPP, verifikasi resep Owner, produksi FIFO, dan checkout atomik belum dihubungkan ke frontend pada paket ini.
- Sebelum mengaktifkan fungsi-fungsi tersebut perlu audit schema live dan pengujian transaksi rollback/idempotency.

## Deployment
Deploy sebagai satu folder publish (isi ZIP diekstrak ke root deploy). Jangan menjalankan file migrasi SQL yang ada di paket tanpa audit database live dan backup.
