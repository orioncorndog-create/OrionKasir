# OR!ON CORNDOG POS Professional — Phase 5

## Cakupan
- Halaman Inventaris & Resep (BOM) untuk Owner/Manajer.
- Master bahan baku dengan satuan dasar `g`, `ml`, atau `pcs`.
- Stok masuk, penyesuaian masuk/keluar, waste, expired, dan stok opname.
- Riwayat pergerakan stok dan indikator stok minimum.
- Penyimpanan resep per menu sebagai versi baru; satu versi aktif per menu.
- RPC `SECURITY DEFINER` dengan validasi role backend dan audit log.

## File migration
Jalankan `migration_phase5_inventory_bom.sql` di Supabase SQL Editor setelah backup database dan setelah migration Phase 2 + Phase 3 + Phase 4. Uji dahulu pada project staging. Migration bersifat additive; tidak mengubah `pos_state`, data penjualan historis, atau menu lama.

## Catatan operasional
- Resep tidak diisi otomatis. Isi takaran berdasarkan standar produksi yang sudah diverifikasi.
- Harga pembelian yang diinput adalah total biaya pembelian untuk jumlah pembelian; backend menyimpan harga rata-rata per satuan pada snapshot bahan.
- Satuan dasar bahan tidak dapat diubah setelah ada riwayat stok atau resep terkait.
- Pengurangan bahan otomatis saat checkout BELUM diaktifkan pada Phase 5. Jangan menganggap stok bahan sudah terpotong ketika transaksi kasir terjadi.
- Integrasi checkout ke `payment_records` dan pengurangan BOM secara atomik perlu diselesaikan pada Phase 6 sebelum shift reconciliation dan pemakaian stok otomatis dijadikan dasar operasional.
- Mode lokal/demo tidak menyimpan inventaris resmi. Fitur ini memerlukan Supabase Auth, migrasi, dan role Owner/Manajer.

## RPC baru
- `orion_inventory_list()`
- `orion_inventory_save_material(uuid,text,text,text,numeric,text)`
- `orion_inventory_stock_move(uuid,text,numeric,text,numeric)`
- `orion_inventory_save_recipe(text,text,jsonb,boolean)`

## Pengujian
Pemeriksaan statis JavaScript dilakukan dengan `node --check`. SQL belum dijalankan terhadap database Supabase dan belum diuji pada transaksi nyata. Uji pada staging untuk role, RLS, constraint, race condition, serta hasil stok sebelum produksi.
