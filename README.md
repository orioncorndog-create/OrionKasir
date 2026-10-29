# OR!ON CORNDOG POS Pro v2.18

Patch perbaikan background kasir: pseudo-element background sekarang memakai lebar viewport `100vw`, dipusatkan dengan `left:50%` dan `translateX(-50%)`, serta tinggi rasio 4:3 eksplisit. Ini mencegah background mengikuti container sempit sehingga tampil hanya di sisi kiri. Cache service worker dan versi aset diperbarui ke v2.18.

Deploy seluruh isi folder ini ke hosting. Setelah deploy, tutup aplikasi/PWA lalu buka kembali; jika masih memakai aset lama, hapus cache situs atau pasang ulang PWA.
