# OR!ON CORNDOG POS PRO — Patch Integrasi Inventaris & HPP

Patch ini menambahkan tampilan laporan HPP resep dan pembaruan harga bahan baku tanpa mengubah stok.

## Perubahan
- Tabel bahan menampilkan harga per satuan dasar.
- Stok lama yang belum pernah dihitung fisik ditampilkan sebagai **Belum dihitung / Tidak dilacak**, bukan dianggap stok nol/minimum.
- Setelah pergerakan stok eksplisit dicatat, `stock_tracking_enabled` menjadi true.
- Tombol **Update harga** memanggil `orion_inventory_update_material_price`; harga dihitung dari total pembelian dibagi jumlah dalam satuan dasar dan tidak mengubah stok.
- Panel **Laporan HPP Resep** memanggil `orion_inventory_hpp_report` dan menandai resep dengan harga bahan yang belum lengkap.

## Urutan pemasangan aman
1. Backup database Supabase.
2. Uji `migration_phase5_hpp_engine_addon.sql` pada project staging terlebih dahulu.
3. Periksa hasil verifikasi SQL di bagian akhir file migration.
4. Deploy source code dari folder ini setelah pengujian staging lulus.
5. Login sebagai Owner/Admin/Manager, buka Inventaris, lalu tekan **Muat ulang** dan **Hitung HPP**.

## Batasan yang tetap berlaku
- Patch ini tidak memasukkan data bahan atau resep secara otomatis.
- Patch ini tidak mengaktifkan pemotongan stok saat checkout.
- Patch ini tidak mengubah `pos_state`, produk, HPP produk lama, penjualan, pembayaran, atau shift.
- Jangan jalankan ulang migrasi Phase 2–5 yang sudah terpasang.
- Jangan mengaktifkan resep sebelum takaran per menu diverifikasi.
- Harga update hanya mengubah harga pembelian terkini, bukan stok fisik.

## Pemeriksaan
`node --check js/app.js` berhasil dijalankan pada source hasil patch. SQL belum dijalankan ke Supabase, sehingga wajib diuji di staging sebelum produksi.
