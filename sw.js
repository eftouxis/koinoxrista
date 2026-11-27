// Απλός service worker: η εφαρμογή ανοίγει σαν εφαρμογή κινητού.
// Πάντα φέρνει την πιο πρόσφατη έκδοση από το δίκτυο· την αποθηκευμένη μόνο αν δεν υπάρχει σύνδεση.
const C = 'koinoxrista-v1';
self.addEventListener('install', e => { self.skipWaiting(); e.waitUntil(caches.open(C).then(c => c.addAll(['./', 'index.html', 'manifest.json', 'icon-192.png']))); });
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', e => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || u.origin !== location.origin) return;
  e.respondWith(fetch(e.request).then(r => { const cp = r.clone(); caches.open(C).then(c => c.put(e.request, cp)); return r; }).catch(() => caches.match(e.request).then(r => r || caches.match('index.html'))));
});
