(() => {
  "use strict";
  const $ = (selector) => document.querySelector(selector);
  const rupiah = (value) => new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(value || 0);
  const STORAGE = { transactions: "orion_pos_transactions_v1", cart: "orion_pos_cart_v1" };
  let transactions = readJSON(STORAGE.transactions, []);
  let cart = readJSON(STORAGE.cart, []);
  let activeCategory = "Semua";
  let toastTimer;

  function readJSON(key, fallback) {
    try { const parsed = JSON.parse(localStorage.getItem(key)); return parsed ?? fallback; }
    catch { return fallback; }
  }
  function persistCart() { localStorage.setItem(STORAGE.cart, JSON.stringify(cart)); }
  function safeText(value) {
    return String(value).replace(/[&<>"']/g, (char) => ({ "&":"&amp;", "<":"&lt;", ">":"&gt;", '"':"&quot;", "'":"&#39;" }[char]));
  }
  function showToast(message) {
    const toast = $("#toast"); toast.textContent = message; toast.classList.add("show");
    clearTimeout(toastTimer); toastTimer = setTimeout(() => toast.classList.remove("show"), 2600);
  }
  function saveTransactions() { localStorage.setItem(STORAGE.transactions, JSON.stringify(transactions)); }
  function getProduct(id) { return PRODUCTS.find((product) => product.id === Number(id)); }
  function totals(items = cart) {
    return items.reduce((sum, item) => {
      const p = getProduct(item.id);
      if (!p) return sum;
      sum.qty += item.qty; sum.sales += p.price * item.qty; sum.hpp += p.hpp * item.qty;
      return sum;
    }, { qty: 0, sales: 0, hpp: 0, profit: 0 });
  }
  function todayTransactions() {
    const today = new Date().toLocaleDateString("en-CA");
    return transactions.filter((t) => new Date(t.createdAt).toLocaleDateString("en-CA") === today);
  }
  function renderMetrics() {
    const list = todayTransactions();
    const sales = list.reduce((n, t) => n + t.totalSales, 0);
    const hpp = list.reduce((n, t) => n + t.totalHpp, 0);
    $("#metric-sales").textContent = rupiah(sales);
    $("#metric-hpp").textContent = rupiah(hpp);
    $("#metric-profit").textContent = rupiah(sales - hpp);
    $("#metric-count").textContent = `${list.length} transaksi hari ini`;
  }
  function renderCategories() {
    const categories = ["Semua", ...new Set(PRODUCTS.map((p) => p.category))];
    $("#category-filters").innerHTML = categories.map((cat) => `<button class="filter-btn ${cat === activeCategory ? "active" : ""}" data-category="${safeText(cat)}">${safeText(cat)}</button>`).join("");
  }
  function renderProducts() {
    const query = $("#search").value.trim().toLocaleLowerCase("id");
    const filtered = PRODUCTS.filter((p) => (activeCategory === "Semua" || p.category === activeCategory) && `${p.name} ${p.category}`.toLocaleLowerCase("id").includes(query));
    $("#product-count").textContent = `${filtered.length} produk`;
    $("#product-grid").innerHTML = filtered.length ? filtered.map((p) => `
      <button class="product-card" data-add="${p.id}" aria-label="Tambah ${safeText(p.name)} ke keranjang">
        <span class="product-visual">${p.icon || "🍴"}</span><span class="product-category">${safeText(p.category)}</span>
        <span class="product-name">${safeText(p.name)}</span><span class="product-card-bottom"><span class="product-price">${rupiah(p.price)}</span><span class="add-mark">+</span></span>
      </button>`).join("") : `<div class="no-products">Menu tidak ditemukan. Coba kata kunci lain.</div>`;
  }
  function renderCart() {
    const t = totals(); t.profit = t.sales - t.hpp;
    $("#cart-count").textContent = t.qty;
    $("#cart-sales").textContent = rupiah(t.sales);
    $("#cart-hpp").textContent = rupiah(t.hpp);
    $("#cart-profit").textContent = rupiah(t.profit);
    $("#cart-items").innerHTML = cart.length ? cart.map((item) => {
      const p = getProduct(item.id); if (!p) return "";
      return `<div class="cart-item"><div><div class="cart-item-name">${safeText(p.name)}</div><div class="cart-item-meta">${rupiah(p.price)} / pcs</div><div class="qty-control"><button data-qty="${p.id}" data-delta="-1" aria-label="Kurangi ${safeText(p.name)}">−</button><span>${item.qty}</span><button data-qty="${p.id}" data-delta="1" aria-label="Tambah ${safeText(p.name)}">+</button></div></div><div class="cart-item-total">${rupiah(p.price * item.qty)}</div></div>`;
    }).join("") : `<div class="empty-cart"><span>＋</span><strong>Belum ada pesanan</strong><small>Pilih menu untuk mulai transaksi.</small></div>`;
    updatePayment();
    persistCart();
  }
  function addToCart(id) {
    const existing = cart.find((item) => item.id === Number(id));
    if (existing) existing.qty++; else cart.push({ id: Number(id), qty: 1 });
    renderCart();
    const product = getProduct(id); if (product) showToast(`${product.name} ditambahkan`);
  }
  function changeQty(id, delta) {
    const item = cart.find((row) => row.id === Number(id)); if (!item) return;
    item.qty += delta; if (item.qty <= 0) cart = cart.filter((row) => row.id !== Number(id));
    renderCart();
  }
  function updatePayment() {
    const method = $("#payment-method").value;
    const cashArea = $("#cash-area");
    cashArea.hidden = method !== "CASH";
    $("#change-row").hidden = method !== "CASH";
    const t = totals();
    const received = Math.max(0, Number($("#cash-received").value) || 0);
    $("#change-value").textContent = rupiah(Math.max(0, received - t.sales));
    $("#checkout-btn").disabled = !cart.length || (method === "CASH" && received < t.sales);
  }
  function checkout() {
    if (!cart.length) return;
    const t = totals(); const method = $("#payment-method").value;
    const received = method === "CASH" ? Math.max(0, Number($("#cash-received").value) || 0) : t.sales;
    if (method === "CASH" && received < t.sales) { showToast("Uang diterima belum mencukupi."); return; }
    const transaction = {
      id: `OR-${Date.now()}`, createdAt: new Date().toISOString(), paymentMethod: method,
      items: cart.map((item) => { const p = getProduct(item.id); return { id: p.id, name: p.name, category: p.category, qty: item.qty, price: p.price, hpp: p.hpp }; }),
      totalQty: t.qty, totalSales: t.sales, totalHpp: t.hpp, grossProfit: t.sales - t.hpp,
      cashReceived: received, change: method === "CASH" ? received - t.sales : 0
    };
    transactions.unshift(transaction); saveTransactions();
    cart = []; persistCart(); $("#cash-received").value = "";
    renderCart(); renderMetrics(); renderHistory(); showReceipt(transaction);
    showToast("Transaksi berhasil disimpan.");
  }
  function renderHistory() {
    const list = $("#history-list");
    $("#history-summary").textContent = `${transactions.length} transaksi tersimpan`;
    if (!transactions.length) { list.innerHTML = `<div class="history-empty">Belum ada riwayat transaksi.</div>`; return; }
    list.innerHTML = transactions.map((t) => {
      const date = new Date(t.createdAt);
      return `<div class="history-row"><div><strong>${safeText(t.id)}</strong><small>${date.toLocaleString("id-ID")} · ${t.totalQty} item · ${t.paymentMethod === "CASH" ? "Tunai" : "QRIS"}</small><small>HPP ${rupiah(t.totalHpp)} · Laba ${rupiah(t.grossProfit)}</small></div><div class="history-total">${rupiah(t.totalSales)}</div></div>`;
    }).join("");
  }
  function showReceipt(t) {
    $("#receipt-content").innerHTML = `<div class="receipt-title">OR!ON CORNDOG</div><div class="receipt-sub">STRUK PENJUALAN · ${safeText(t.id)}</div><div class="receipt-sub">${new Date(t.createdAt).toLocaleString("id-ID")}</div><div class="receipt-rule"></div>${t.items.map((item) => `<div class="receipt-line"><span>${safeText(item.name)} × ${item.qty}</span><strong>${rupiah(item.price * item.qty)}</strong></div>`).join("")}<div class="receipt-rule"></div><div class="receipt-line receipt-total"><span>TOTAL</span><strong>${rupiah(t.totalSales)}</strong></div><div class="receipt-line"><span>Metode</span><strong>${t.paymentMethod === "CASH" ? "Tunai" : "QRIS"}</strong></div>${t.paymentMethod === "CASH" ? `<div class="receipt-line"><span>Uang diterima</span><strong>${rupiah(t.cashReceived)}</strong></div><div class="receipt-line"><span>Kembalian</span><strong>${rupiah(t.change)}</strong></div>` : ""}<div class="receipt-rule"></div><div class="receipt-line"><span>HPP (estimasi)</span><strong>${rupiah(t.totalHpp)}</strong></div><div class="receipt-line"><span>Laba kotor (estimasi)</span><strong>${rupiah(t.grossProfit)}</strong></div><div class="receipt-sub" style="margin-top:20px">Terima kasih telah berbelanja!</div>`;
    $("#receipt-dialog").showModal();
  }
  function exportCSV() {
    if (!transactions.length) { showToast("Belum ada data untuk diekspor."); return; }
    const rows = [["ID Transaksi","Tanggal","Metode","Produk","Qty","Harga Jual","HPP Satuan","Subtotal","Total Omset","Total HPP","Laba Kotor"]];
    transactions.forEach((t) => t.items.forEach((item) => rows.push([t.id, new Date(t.createdAt).toLocaleString("id-ID"), t.paymentMethod, item.name, item.qty, item.price, item.hpp, item.price * item.qty, t.totalSales, t.totalHpp, t.grossProfit])));
    const csv = "\uFEFF" + rows.map((row) => row.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(",")).join("\r\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob); const a = document.createElement("a"); a.href = url; a.download = `orion-pos-riwayat-${new Date().toISOString().slice(0,10)}.csv`; a.click(); URL.revokeObjectURL(url);
  }
  $("#category-filters").addEventListener("click", (e) => { const btn = e.target.closest("[data-category]"); if (!btn) return; activeCategory = btn.dataset.category; renderCategories(); renderProducts(); });
  $("#product-grid").addEventListener("click", (e) => { const btn = e.target.closest("[data-add]"); if (btn) addToCart(btn.dataset.add); });
  $("#cart-items").addEventListener("click", (e) => { const btn = e.target.closest("[data-qty]"); if (btn) changeQty(btn.dataset.qty, Number(btn.dataset.delta)); });
  $("#search").addEventListener("input", renderProducts);
  $("#payment-method").addEventListener("change", updatePayment);
  $("#cash-received").addEventListener("input", updatePayment);
  $("#checkout-btn").addEventListener("click", checkout);
  $("#clear-cart").addEventListener("click", () => { if (!cart.length) return; cart = []; $("#cash-received").value = ""; renderCart(); showToast("Keranjang dikosongkan."); });
  $("#history-btn").addEventListener("click", () => { renderHistory(); $("#history-dialog").showModal(); });
  $("#export-csv").addEventListener("click", exportCSV);
  $("#clear-history").addEventListener("click", () => {
    if (!transactions.length) return;
    if (confirm("Hapus seluruh riwayat transaksi dari perangkat ini? Tindakan ini tidak bisa dibatalkan.")) {
      transactions = []; saveTransactions(); renderHistory(); renderMetrics(); showToast("Riwayat transaksi dihapus.");
    }
  });
  $("#print-receipt").addEventListener("click", () => window.print());
  document.querySelectorAll("[data-close]").forEach((button) => button.addEventListener("click", () => $("#" + button.dataset.close).close()));
  document.querySelectorAll("dialog").forEach((dialog) => dialog.addEventListener("click", (e) => { if (e.target === dialog) dialog.close(); }));
  document.addEventListener("keydown", (e) => { if (e.key === "/" && !["INPUT","TEXTAREA"].includes(document.activeElement.tagName)) { e.preventDefault(); $("#search").focus(); } });
  function updateOnlineStatus() {
    const status = $("#offline-status");
    status.classList.toggle("offline", !navigator.onLine);
    status.innerHTML = `<i></i> ${navigator.onLine ? "Online" : "Offline"}`;
  }
  window.addEventListener("online", updateOnlineStatus); window.addEventListener("offline", updateOnlineStatus);
  if ("serviceWorker" in navigator && (location.protocol === "https:" || location.hostname === "localhost")) {
    window.addEventListener("load", () => navigator.serviceWorker.register("./service-worker.js").catch((err) => console.warn("Service worker gagal didaftarkan:", err)));
  }
  renderCategories(); renderProducts(); renderCart(); renderMetrics(); updateOnlineStatus();
})();
