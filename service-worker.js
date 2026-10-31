const CACHE="orion-pos-v5.1";
const ASSETS=["./","./index.html","./css/styles.css?v=5.1","./js/db.js","./js/app.js?v=5.1","./js/supabase-config.js","./manifest.json","./icons/icon-192.png","./icons/icon-512.png","./assets/icon_omzet_hari_ini.png","./assets/icon_hpp_terjual.png","./assets/icon_laba_kotor.png","./assets/orion-logo.jpg","./assets/orion-logo-full-4k.png"];
self.addEventListener("install",event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(ASSETS)).then(()=>self.skipWaiting())));
self.addEventListener("activate",event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key!==CACHE).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener("fetch",event=>{
  if(event.request.method!=="GET"||new URL(event.request.url).origin!==self.location.origin)return;
  event.respondWith(caches.match(event.request).then(cached=>cached||fetch(event.request).then(response=>{
    if(response&&response.ok){const copy=response.clone();caches.open(CACHE).then(cache=>cache.put(event.request,copy));}
    return response;
  }).catch(()=>caches.match("./index.html"))));
});
