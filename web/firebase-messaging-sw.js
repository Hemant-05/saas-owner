importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBlSd1gYDWP7XvsW9ELG8ecgnmYhDOuWq8',
  authDomain: 'saas-5116b.firebaseapp.com',
  projectId: 'saas-5116b',
  storageBucket: 'saas-5116b.firebasestorage.app',
  messagingSenderId: '932259613195',
  appId: '1:932259613195:web:72c84386ba71b8b179d50e',
  measurementId: 'G-58KMNZMES4',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};

  self.registration.showNotification(notification.title || 'New update', {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data,
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const targetUrl = '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.focus();
          client.postMessage({ type: 'notification-click', data });
          return;
        }
      }
      if (clients.openWindow) return clients.openWindow(targetUrl);
    }),
  );
});
