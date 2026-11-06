const V='giocha-v29.4',A=['./vendor/supabase.js','./','./index.html','./config.js','./manifest.json','./icon-192.png','./icon-512.png','./icon-maskable-512.png','./apple-touch-icon.png','./favicon-32.png'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(V).then(c=>Promise.all(A.map(u=>fetch(new Request(u,{cache:'reload'})).then(r=>r.ok?c.put(u,r):0).catch(()=>0)))));self.skipWaiting()});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==V).map(x=>caches.delete(x)))));self.clients.claim()});
self.addEventListener('fetch',e=>{const q=e.request;if(q.method!=='GET')return;const u=new URL(q.url);
if(u.pathname.indexOf('/storage/v1/object/public/')>-1){e.respondWith(caches.match(q).then(r=>r||fetch(q).then(x=>{if(x.ok){const c=x.clone();caches.open(V).then(z=>z.put(q,c))}return x})));return}
if(u.hostname.endsWith('supabase.co'))return;
if(u.origin!==location.origin){e.respondWith(fetch(q).then(r=>{const c=r.clone();caches.open(V).then(x=>x.put(q,c));return r}).catch(()=>caches.match(q)));return}
e.respondWith(caches.open(V).then(c=>c.match(q,{ignoreSearch:true}).then(hit=>{const net=fetch(q).then(r=>{if(r.ok&&r.type==='basic')c.put(q,r.clone());return r}).catch(()=>null);if(hit){e.waitUntil(net);return hit}return net.then(r=>r||c.match('./index.html'))})))});
