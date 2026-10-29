# OR!ON CORNDOG POS Pro v2.21 — Responsive Dashboard

## Revisi layout v2.21
- Layout utama dan konten memakai lebar fleksibel penuh, tanpa pembatas max-width yang menyempitkan halaman.
- Pada tablet/iPad (lebar 768 px ke atas), sidebar navigasi tampil permanen di kiri dan bukan edge panel.
- Pada layar 1024 px ke atas, halaman kasir menggunakan dashboard dua kolom (katalog dan keranjang).
- Kartu metrik dan grid produk menyesuaikan ukuran layar; tabel tetap dapat digeser di dalam pembungkusnya tanpa membuat seluruh halaman melebar.
- Pada HP, navigasi tetap memakai edge panel dan grid produk tetap dua kolom.

## Deploy
Unggah seluruh isi folder hasil ekstrak ke hosting Netlify untuk menggantikan versi sebelumnya. Service worker dan query asset diperbarui ke v2.21. Setelah deploy, muat ulang situs atau bersihkan cache bila masih tampil versi lama.

## Supabase
Jika memakai sinkronisasi online, isi `js/supabase-config.js` dengan Project URL dan publishable/anon key Supabase, lalu jalankan `schema.sql` pada SQL Editor. Jangan gunakan service_role key di browser.


## v2.22 patch
- Corrected cashier background alignment to use viewport-centered full-bleed positioning (100vw) without horizontal translation offsets.
- Kept 4:3 background area and cover crop.
- Changed horizontal category chip scrollbar from grey to a thin wine-red indicator.


## v2.23 — Reset background kasir
- Added a **Hapus background** button beside the cashier background image control. It appears only when a custom background is active.
- Removing the custom image clears the saved `cashierHeaderImage` setting, restores the default cashier background, persists the change, and refreshes the UI.
- Added a confirmation prompt to prevent accidental removal.
- Updated service worker cache version to v2.23.

## v2.24 — Background layout & visual customization
- Isolated cashier background in an absolutely positioned 4:3 layer aligned to the viewport; the background no longer participates in layout sizing or pushes foreground content sideways.
- Consolidated background actions into a top-right three-dot menu: change background image, reset to default, and customize colors/fonts.
- Added saved theme controls for page background, card/panel background, primary buttons, sidebar, payment bubbles, text color, and font family.
- Theme settings are stored in the existing application settings and applied through CSS variables. The reset button inside the theme dialog returns the controls to default values; saving persists the selected theme.
- Updated asset and service-worker cache versions to v2.24.
