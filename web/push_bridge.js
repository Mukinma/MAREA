// Capture a tap before Flutter boots or Supabase handles its auth callback.
(() => {
  let onOpen, pending;
  const worker = new URL('push/firebase-messaging-sw.js', document.baseURI);
  const scope = new URL('./', worker);
  const cold = /^#marea-push=([a-f0-9-]{36})\.([a-f0-9-]{36})$/i.exec(location.hash);
  if (cold) {
    pending = { notification_id: cold[1], recipient_id: cold[2] };
    history.replaceState(history.state, '', location.pathname + location.search);
  }
  navigator.serviceWorker?.addEventListener('message', event => {
    if (!event.source?.scriptURL || event.data?.type !== 'marea:open-push') return;
    const source = new URL(event.source.scriptURL);
    if (source.origin !== worker.origin || source.pathname !== worker.pathname) return;
    if (onOpen) onOpen(JSON.stringify(event.data.notice));
    else pending = event.data.notice;
  });

  async function registration() {
    const reg = await navigator.serviceWorker?.getRegistration(scope.href);
    // getRegistration can return a parent-scope Flutter service worker.
    return reg?.scope === scope.href ? reg : undefined;
  }
  window.mareaPush = {
    listen(callback) {
      onOpen = callback;
      if (pending && onOpen) {
        const notice = pending;
        pending = null;
        onOpen(JSON.stringify(notice));
      }
    },
    absoluteWorkerUrl(path) { return new URL(path, document.baseURI).href; },
    async show(title, body, payload, quiet) {
      const reg = await registration();
      if (!reg) throw Error('push_worker_unavailable');
      const notice = JSON.parse(payload);
      await reg.showNotification(title, { body, data: notice, tag: notice.notification_id,
        silent: quiet, icon: new URL('icons/Icon-192.png', document.baseURI).href });
    },
    async clear() {
      const reg = await registration();
      if (reg) for (const item of await reg.getNotifications()) item.close();
    }
  };
})();
