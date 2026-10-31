# PHASE 4 — Shift Management Frontend

## Implementasi pada source
- Menambahkan halaman **Shift Kasir** ke navigasi existing.
- Membaca shift aktif, daftar cash drawer, shared shift yang dapat diikuti, dan riwayat shift melalui Supabase RPC.
- Mendukung buka shift individual/shared, pembuatan cash drawer oleh Owner/Manager, join/leave shared shift, pencatatan kas masuk/keluar/cash drop, dan tutup shift/rekonsiliasi.
- Menampilkan error backend secara eksplisit; UI tidak menulis langsung ke tabel shift.
- Akses kasir dan manager ke halaman shift ditambahkan pada navigasi; otorisasi operasi tetap divalidasi oleh RPC di server.
- Tidak mengaktifkan checkout gate dan tidak mengubah checkout lama. Hal ini disengaja karena checkout legacy belum mengisi `payment_records`, sehingga hasil rekonsiliasi belum dapat mencakup seluruh transaksi.

## Migrasi tambahan Phase 4
Jalankan `migration_phase4_shift_ui.sql` setelah:
1. Backup Supabase.
2. `migration_professional_phase2.sql`.
3. `migration_phase3_shift_rpc.sql`.

Migrasi Phase 4 menambahkan RPC baca:
- `orion_shift_open_shared()` — daftar shared drawer yang terbuka dan dapat diikuti.
- `orion_shift_history(integer)` — riwayat shift sesuai role/keanggotaan pengguna.

Semua operasi tetap memakai RPC `SECURITY DEFINER` dengan identitas dari Supabase Auth. Tidak ada grant akses langsung browser ke tabel shift.

## Status dan batasan
- Source/UI selesai diintegrasikan secara statis.
- Migrasi SQL hanya ditinjau secara statis; belum dijalankan di Supabase asli.
- Belum diuji dengan akun Owner/Manager/Kasir yang terpisah.
- Belum ada tampilan rincian anggota per shift atau pengelolaan keanggotaan orang lain (misalnya mengeluarkan anggota oleh Owner/Manager). Kasir dapat join/leave shift miliknya sesuai RPC yang tersedia.
- Total penjualan, QRIS, transfer, dan non-tunai belum dapat direkonsiliasi lengkap karena checkout existing belum menulis payment records.
- Shift gate checkout belum diaktifkan untuk mencegah transaksi lama menjadi tidak konsisten.
- Mode lokal/demo tidak menyediakan shift backend; layar memberi pemberitahuan dan tidak membuat data shift palsu.

## Uji statis yang harus dilakukan sebelum staging
- Jalankan `node --check js/app.js`.
- Terapkan seluruh migrasi pada project Supabase staging.
- Uji open/join/leave/cash movement/close/history dengan akun berbeda.
- Pastikan RLS dan EXECUTE grants sesuai hasil SQL staging.
