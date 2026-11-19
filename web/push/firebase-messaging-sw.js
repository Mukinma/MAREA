// This worker has its own /push/ scope. Its URL carries only the public app
// registration used by FlutterFire to subscribe the browser.
const appRoot = new URL('../', self.location.href);
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function noticeIds(data) {
  if (!data || !uuid.test(data.notification_id) || !uuid.test(data.recipient_id)) return null;
  return { notification_id: data.notification_id, recipient_id: data.recipient_id };
}

// Install before Firebase so a click always goes through MAREA's account check.
self.addEventListener('notificationclick', event => {
  const data = event.notification.data;
  const notice = noticeIds(data) || noticeIds(data?.FCM_MSG?.data);
  if (!notice) return;
  event.stopImmediatePropagation();
  event.notification.close();
  event.waitUntil((async () => {
    const windows = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    const window = windows.find(client => {
      const url = new URL(client.url);
      return url.origin === appRoot.origin && url.pathname.startsWith(appRoot.pathname);
    });
    if (window) {
      await window.focus();
      window.postMessage({ type: 'marea:open-push', notice });
    } else {
      // A fragment is local to the browser and does not enter HTTP access logs.
      const target = new URL(appRoot);
      target.hash = 'marea-push=' + notice.notification_id + '.' + notice.recipient_id;
      await clients.openWindow(target.href);
    }
  })());
});

// Keep this version aligned with firebase_core_web's supportedFirebaseJsSdkVersion.
importScripts(
  'https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js',
  'https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js'
);
const params = new URL(self.location.href).searchParams;
firebase.initializeApp({
  apiKey: params.get('apiKey'),
  appId: params.get('appId'),
  messagingSenderId: params.get('messagingSenderId'),
  projectId: params.get('projectId')
});
firebase.messaging().onBackgroundMessage(payload => {
  // Older workers sent a notification envelope. The SDK already displayed it.
  if (payload.notification) return;
  const data = payload.data;
  const notice = noticeIds(data);
  if (!notice) return;
  return self.registration.showNotification(data.title || 'MAREA', {
    body: data.body || '',
    tag: notice.notification_id,
    silent: data.category === 'reminders',
    icon: new URL('icons/Icon-192.png', appRoot).href,
    data: notice
  });
});
