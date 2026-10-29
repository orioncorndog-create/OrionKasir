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


## v2.27 — Supabase & akun staf
- URL project dan publishable key Supabase sudah diisikan ke `js/supabase-config.js`.
- Login/daftar mendukung email + password dan nomor HP format internasional (`+628...`). Phone Auth memerlukan penyedia SMS yang diaktifkan di Supabase.
- Email signup memakai redirect kembali ke URL aplikasi saat ini. Tambahkan URL aplikasi yang benar ke Supabase Authentication → URL Configuration → Redirect URLs; untuk localhost, tambahkan URL localhost yang digunakan saat uji.
- Pengaturan akun menampilkan formulir pembuatan akun staf hanya untuk role owner. Peran manager ditetapkan melalui fungsi SQL `pos_owner_set_role`; jalankan `schema.sql` yang diperbarui.
- Akun yang dibuat melalui aplikasi pertama kali perlu role owner ditetapkan secara manual untuk akun pemilik.

### Menetapkan akun pertama sebagai owner
Setelah akun pemilik dibuat dan email dikonfirmasi, jalankan di SQL Editor (ganti alamat email):
```sql
update public.pos_profiles p set role='owner', updated_at=now()
from auth.users u where p.id=u.id and u.email='email-pemilik@contoh.com';
```
Catatan keamanan: versi ini menggunakan satu snapshot `pos_state` bersama. Pembatasan menu di antarmuka adalah kontrol UI; untuk keamanan produksi yang ketat, backend perlu dinormalisasi/ditambah RPC tervalidasi agar karyawan tidak dapat mengubah data selain transaksi melalui API langsung.
