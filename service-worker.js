const CACHE="orion-pos-v2.38-login-rpc";
const ASSETS=["./","./index.html","./css/styles.css?v=2.38","./js/db.js","./js/app.js?v=2.38","./js/supabase-config.js","./manifest.json","./icons/icon-192.png","./icons/icon-512.png","./assets/icon_omzet_hari_ini.png","./assets/icon_hpp_terjual.png","./assets/icon_laba_kotor.png"];
self.addEventListener("install",event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(ASSETS)).then(()=>self.skipWaiting())));
self.addEventListener("activate",event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key!==CACHE).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener("fetch",event=>{
 const request=event.request;
 if(request.method!=="GET"||new URL(request.url).origin!==self.location.origin)return;
 const url=new URL(request.url);
 const isDocument=request.mode==="navigate"||url.pathname.endsWith(".html");
 const isCode=/\.(?:js|css)$/.test(url.pathname);
 if(isDocument||isCode){
  event.respondWith(fetch(request).then(response=>{
   if(response&&response.ok){const copy=response.clone();caches.open(CACHE).then(cache=>cache.put(request,copy));}
   return response;
  }).catch(()=>caches.match(request).then(cached=>cached||(isDocument?caches.match("./index.html"):Response.error()))));
  return;
 }
 event.respondWith(caches.match(request).then(cached=>cached||fetch(request).then(response=>{
  if(response&&response.ok){const copy=response.clone();caches.open(CACHE).then(cache=>cache.put(request,copy));}
  return response;
 })));
});
