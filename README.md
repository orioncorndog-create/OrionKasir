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


## v2.28 — Verifikasi email dan alur kembali ke aplikasi
- Layar pendaftaran menjelaskan dengan jelas bahwa pengguna harus membuka Gmail dan menekan tautan verifikasi terlebih dahulu.
- Setelah callback verifikasi kembali ke URL aplikasi dan Supabase membentuk sesi, aplikasi membuka POS dan menampilkan pesan berhasil login.
- Login callback menggunakan PKCE dan memeriksa sesi setelah redirect.

### Wajib dilakukan di Supabase agar email benar-benar terkirim
1. Buka Authentication → Providers → Email dan pastikan Email provider aktif serta Confirm email diaktifkan.
2. Buka Authentication → URL Configuration. Isi Site URL dengan URL aplikasi yang benar dan tambahkan URL lengkap aplikasi ke Redirect URLs, misalnya `https://domain-netlify-anda.netlify.app/` (gunakan domain asli milik Anda).
3. Untuk pengiriman ke Gmail pelanggan/pengguna umum, konfigurasi SMTP provider sendiri di Authentication → SMTP Settings. SMTP bawaan Supabase umumnya hanya untuk uji coba dan memiliki batasan penerima/pengiriman; memasukkan URL/key saja tidak mengaktifkan layanan email produksi.
4. Periksa folder Spam/Promosi dan log email/Auth di Supabase. Pastikan template Confirm signup menggunakan `{{ .ConfirmationURL }}` agar Supabase memverifikasi token lalu mengarahkan ke `emailRedirectTo` aplikasi.
5. Setelah verifikasi, pengguna akan login otomatis hanya jika tautan redirect diizinkan, proses callback berhasil, dan pengaturan Auth/template mendukung pembentukan sesi. Jika tidak, pengguna dapat kembali ke layar login dan masuk secara manual.

Catatan: aplikasi tidak dapat memaksa email terkirim jika SMTP/provider Supabase belum dikonfigurasi. Nomor HP menggunakan SMS, bukan Gmail, dan memerlukan Phone Auth serta penyedia SMS aktif.


## v2.29 — Akun hanya aktif setelah verifikasi
- `schema.sql` kini membuat profil POS hanya setelah email/nomor HP terverifikasi. Akun pending yang belum terverifikasi dibersihkan dari `pos_profiles`.
- Layar daftar menegaskan akun belum aktif sampai verifikasi berhasil.
- Catatan penting: Supabase Auth tetap menyimpan record pending di `auth.users` untuk mengirim dan memvalidasi token; ini perilaku normal, bukan akun yang sudah bisa digunakan.
- Untuk email ke Gmail, aktifkan Confirm email dan konfigurasi SMTP provider di Supabase. URL/key saja tidak mengirim email.
- Jalankan `schema.sql` versi ini di Supabase SQL Editor. Query aman menghapus hanya profil yang belum terverifikasi; periksa sebelum menjalankan jika sebelumnya ada akun uji yang belum dikonfirmasi.


## v2.30 — Pengaturan
- Pengaturan dibagi menjadi Profil & Umum, Hak Akses Pegawai, dan Perangkat Keras.
- Preferensi sinkronisasi, izin peran, dan hardware disimpan dalam data pengaturan POS.
- Pengaturan dapat dibuka oleh Owner dan Manajer; pembuatan akun pegawai dan perubahan hak akses hanya Owner.
- Printer Bluetooth/USB/LAN dan laci uang memerlukan dukungan perangkat/browser/driver. Bagian ini menyimpan preferensi; bukan jaminan koneksi perangkat secara otomatis.
- Email verifikasi dikirim oleh Supabase Auth. Untuk pengiriman email yang andal, konfigurasikan SMTP khusus di Supabase Authentication → SMTP Settings dan cek Authentication → Logs.


## PWA / PWABuilder / Trusted Web Activity (v2.31)

Manifest sudah menggunakan `display: standalone`, `display_override` dengan fallback fullscreen/standalone, scope/start URL relatif, ikon 192/512, dan metadata mobile. Service worker cache dinaikkan ke v2.31.

**Penting:** `display: standalone` tidak sendirinya menjamin APK tidak menampilkan bilah URL. Untuk APK Android tanpa bilah URL, PWABuilder harus membangun aplikasi sebagai **Trusted Web Activity (TWA)** dan domain Netlify harus diverifikasi melalui Digital Asset Links. File `/.well-known/assetlinks.json` tidak dapat diisi valid tanpa domain publik yang benar, Android package/application ID, dan SHA-256 fingerprint sertifikat penandatanganan APK. Setelah PWABuilder menghasilkan/menentukan ketiganya, buat file `/.well-known/assetlinks.json` di situs dengan isi yang disediakan PWABuilder dan pastikan URL tersebut bisa dibuka publik dengan HTTP 200 serta `Content-Type: application/json`. Jangan menebak fingerprint atau package ID.

### Checklist PWABuilder
1. Deploy isi folder ini ke Netlify (HTTPS).
2. Buka URL publik di PWABuilder dan jalankan validasi manifest/service worker.
3. Pilih Android package dengan mode Trusted Web Activity (TWA), bukan sekadar WebView wrapper.
4. Catat Android package name dan SHA-256 fingerprint dari key yang benar-benar dipakai untuk menandatangani APK.
5. Pasang `assetlinks.json` di `/.well-known/assetlinks.json` pada domain yang sama persis dengan start URL.
6. Build ulang APK dan instal. Jika asset links tidak cocok/terjangkau, Chrome dapat menampilkan toolbar URL sebagai fallback.


## v2.32 — Store, printer and payment settings update
- Store profile: email, custom receipt logo, receipt header, timezone, opening/closing hours and optional schedule toggle.
- Printer settings: Bluetooth/Web Bluetooth and USB/WebUSB device selection where supported, LAN/Wi-Fi printer IP, 58/80 mm paper, auto-print toggle, cash drawer setting and test actions. Actual printing/cash-drawer pulses depend on compatible ESC/POS hardware and a supported browser/bridge.
- Payment settings: selectable enabled methods for cash, manual/dynamic QRIS, transfer, debit/credit cards and e-wallets; gateway provider/merchant reference fields. Dynamic QRIS is a configuration scaffold only until a provider API is integrated securely on a backend. Do not store gateway secret keys in frontend code.
- Cashier reporting: sales include cashier identity and a day-based shift key; cashier report view is filtered to their own current-day records. Server-side database policies must still be configured to enforce access securely.
- Quick PIN field saves a device-local preference only; it is not yet a secure login shortcut and must not be treated as account authentication.

## v2.33 — Barang terjual, navigasi dan katalog
- Halaman Stok dialihkan menjadi peringkat barang terjual pada bulan berjalan; data transaksi lama tetap tersimpan dan rekap dihitung ulang otomatis saat bulan berganti.
- Penjualan tidak lagi dibatasi atau mengurangi angka stok. Formulir menu tidak meminta stok.
- Foto menu dikompres lebih ringan dan tetap dipertahankan saat data menu lain diedit; penghapusan foto hanya melalui konfirmasi eksplisit.
- Tombol kembali ke kasir tersedia pada halaman selain kasir. Tombol Back perangkat kembali ke kasir, lalu meminta konfirmasi dua kali untuk keluar.
- Kategori katalog mengikuti urutan kategori yang disimpan dan indikator kategori mengikuti bagian menu yang sedang terlihat.
- Sesi Supabase tetap memanfaatkan sesi persisten perangkat; pengguna perlu logout untuk mengakhiri sesi secara normal.

Catatan: perilaku keluar aplikasi melalui tombol Back bergantung pada browser/PWA/TWA Android yang menjalankan aplikasi. Uji pada APK terpasang. Foto disimpan sebagai data gambar dalam data POS; tetap lakukan backup berkala, terutama bila memakai mode lokal.
