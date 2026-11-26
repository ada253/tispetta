// TiSpetta – service worker
// Strategia "prima la rete": mostra sempre la versione più recente (bandi aggiornati)
// e usa la copia salvata solo quando sei offline.
const CACHE = 'tispetta-v1';
const CORE = [
  './',
  'index.html',
  'bandi.js',
  'privacy.html',
  'termini.html',
  'manifest.webmanifest',
  'icon-192.png',
  'icon-512.png',
  'apple-touch-icon.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(CORE))
      .catch(() => { /* se un file manca, l'app funziona comunque */ })
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);
  // Solo i file di questo sito: le chiamate a Supabase non passano mai dalla cache.
  if (req.method !== 'GET' || url.origin !== self.location.origin) return;

  // La stessa pagina con parametri diversi (?src=tiktok) usa una sola copia.
  const key = url.origin + url.pathname;

  event.respondWith(
    fetch(req)
      .then((res) => {
        if (res.ok) {
          const copy = res.clone();
          caches.open(CACHE).then((cache) => cache.put(key, copy));
        }
        return res;
      })
      .catch(() =>
        caches.match(key).then((cached) =>
          cached || (req.mode === 'navigate' ? caches.match(url.origin + url.pathname.replace(/[^/]*$/, '')) : Response.error())
        )
      )
  );
});
