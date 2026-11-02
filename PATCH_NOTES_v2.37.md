# OR!ON CORNDOG POS Pro — Patch v2.37

## Perubahan yang diterapkan

1. **Auth callback Supabase**: callback `onAuthStateChange` tidak lagi menjalankan operasi Supabase dengan `await` di dalam callback. Pekerjaan sesi dijadwalkan ke microtask agar tidak menahan auth lock.
2. **Urutan inisialisasi auth**: listener dipasang sebelum `getSession()`; pemrosesan sesi dideduplikasi berdasarkan ID user.
3. **Penanganan sign-out**: state pengguna aktif dibersihkan saat event `SIGNED_OUT` dan saat logout manual.
4. **Sinkronisasi snapshot**: penulisan `pos_state` diserialisasi melalui antrean Promise, dan payload diambil sebagai snapshot JSON saat operasi dijalankan.
5. **Penanganan flag pull**: `window.__orionPullingRemote` selalu dipulihkan melalui `finally`, termasuk saat penyimpanan lokal melempar error.
6. **Service worker**: versi cache dinaikkan ke v2.37. Dokumen, JavaScript, dan CSS memakai network-first agar pembaruan aplikasi tidak terus tertahan oleh cache lama; aset statis tetap cache-first.
7. **Cache-busting UI**: URL CSS/JS dan label aplikasi diperbarui ke v2.37.

## Pemeriksaan yang dilakukan

- `node --check js/app.js` — lulus.
- `node --check js/db.js` — lulus.
- `node --check js/supabase-config.js` — lulus.
- `node --check service-worker.js` — lulus.
- Arsip ZIP sumber — integritas ZIP lulus.

## Batasan penting — belum aman diaktifkan untuk produksi

Patch ini **bukan** implementasi HPP FIFO dan tidak mengubah database Supabase.

Arsitektur saat ini masih memakai satu snapshot JSON `pos_state` untuk hampir seluruh state POS. Checkout masih menyimpan transaksi lokal lalu melakukan upsert snapshot; belum ada transaksi database per receipt, idempotency key server-side, reservasi/pengurangan lot FIFO, ledger stok, ataupun rollback atomik saat stok tidak cukup. Antrean penulisan snapshot mengurangi tumpang tindih request dari browser ini, tetapi **tidak** menyelesaikan konflik antar-perangkat atau kehilangan pembaruan akibat stale snapshot.

RLS dalam `schema.sql` sumber masih memberi akses baca/tulis `pos_state` kepada semua role `authenticated` tanpa pemeriksaan role. Jangan menganggap pembatasan UI sebagai keamanan database. Perlu audit dan migrasi RLS/RPC yang disesuaikan dengan data live sebelum produksi.

Tidak ada SQL migrasi yang disertakan atau dijalankan karena belum ada inspeksi live database, verifikasi struktur/tabel/data aktual, backup tervalidasi, dan persetujuan eksekusi. Tidak ada transaksi, akun, atau data Supabase yang diubah.

## Tahap berikutnya yang wajib

1. Hubungkan akses Supabase yang berwenang dan baca-only terlebih dahulu; inventarisasi tabel, constraints, policies, triggers, functions, grants, dan data terkait.
2. Rancang receipt checkout RPC idempotent dan transaksi atomik.
3. Verifikasi pemetaan recipe/BOM ke raw material dan satuan konversinya bersama Owner.
4. Implementasikan receipt/lot, FIFO consumption ledger, reversal/refund, serta shortage rollback.
5. Pisahkan Actual FIFO HPP dari Replacement Cost HPP. Harga pembelian terbaru yang sudah diposting menjadi replacement cost; analytics weighted average 3 pembelian terakhir tetap hanya metrik analitik.
6. Uji dengan data staging/fixture dan bukti hasil sebelum migrasi produksi.

## Keputusan keselamatan

**Jangan aktifkan FIFO atau menjalankan migrasi produksi dari paket ini.** Paket ini hanya patch stabilisasi frontend/auth/cache dengan batasan yang dijelaskan di atas.
