const CACHE="orion-pos-v2.26";
const ASSETS=["./","./index.html","./css/styles.css?v=2.26","./js/db.js","./js/app.js?v=2.26","./js/supabase-config.js","./manifest.json","./icons/icon-192.png","./icons/icon-512.png","./assets/icon_omzet_hari_ini.png","./assets/icon_hpp_terjual.png","./assets/icon_laba_kotor.png"];
self.addEventListener("install",e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting())));
self.addEventListener("activate",e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener("fetch",e=>{if(e.request.method!=="GET"||new URL(e.request.url).origin!==self.location.origin)return;e.respondWith(caches.match(e.request).then(cached=>cached||fetch(e.request).then(res=>{const copy=res.clone();caches.open(CACHE).then(c=>c.put(e.request,copy));return res}).catch(()=>caches.match("./index.html"))))});
