(function () {
  'use strict';

  const appId = '__APP_ID__';
  const runtimeVersion = '__RUNTIME_VERSION__';
  const pending = new Map();
  const listeners = new Map();

  function uuid() {
    if (window.crypto && typeof window.crypto.randomUUID === 'function') {
      return window.crypto.randomUUID();
    }
    return 'req-' + Date.now() + '-' + Math.random().toString(16).slice(2);
  }

  function post(namespace, method, params) {
    return new Promise(function (resolve, reject) {
      const requestId = uuid();
      const payload = {
        requestId: requestId,
        appId: appId,
        namespace: namespace,
        method: method,
        params: params || {}
      };

      const timer = window.setTimeout(function () {
        pending.delete(requestId);
        reject({ code: 'INTERNAL_ERROR', message: 'Bridge request timed out' });
      }, 60 * 60 * 1000);

      pending.set(requestId, {
        resolve: resolve,
        reject: reject,
        timer: timer
      });

      try {
        window.AppRuntimeNative.postMessage(JSON.stringify(payload));
      } catch (error) {
        window.clearTimeout(timer);
        pending.delete(requestId);
        reject({ code: 'INTERNAL_ERROR', message: String(error) });
      }
    });
  }

  function resolveBridgeMessage(message) {
    const response = typeof message === 'string' ? JSON.parse(message) : message;
    const item = pending.get(response.requestId);
    if (!item) {
      return;
    }
    pending.delete(response.requestId);
    window.clearTimeout(item.timer);
    if (response.ok) {
      item.resolve(response.result || {});
    } else {
      item.reject(response.error || {
        code: 'INTERNAL_ERROR',
        message: 'Unknown bridge error'
      });
    }
  }

  window.__AppRuntimeResolve = function (message) {
    if (Array.isArray(message)) {
      message.forEach(resolveBridgeMessage);
      return;
    }
    resolveBridgeMessage(message);
  };

  window.__AppRuntimeResolveBatch = function (messages) {
    if (!Array.isArray(messages)) {
      resolveBridgeMessage(messages);
      return;
    }
    messages.forEach(resolveBridgeMessage);
  };

  window.__AppRuntimeEmit = function (message) {
    const event = typeof message === 'string' ? JSON.parse(message) : message;
    if (!event || typeof event.type !== 'string') {
      return;
    }
    const items = listeners.get(event.type);
    if (!items) {
      return;
    }
    items.slice().forEach(function (listener) {
      try {
        listener(event.payload || {});
      } catch (_) {
        // Listener errors should not break runtime event dispatch.
      }
    });
  };

  function addListener(type, listener) {
    if (typeof listener !== 'function') {
      throw new TypeError('listener must be a function');
    }
    const items = listeners.get(type) || [];
    const shouldSubscribe = items.length === 0;
    items.push(listener);
    listeners.set(type, items);
    if (shouldSubscribe) {
      post('events', 'subscribe', { type: type }).catch(function () {});
    }
    return function unsubscribe() {
      const current = listeners.get(type) || [];
      const next = current.filter(function (item) { return item !== listener; });
      if (next.length === 0) {
        listeners.delete(type);
        post('events', 'unsubscribe', { type: type }).catch(function () {});
      } else {
        listeners.set(type, next);
      }
    };
  }

  window.AppRuntime = Object.freeze({
    runtimeVersion: runtimeVersion,
    device: Object.freeze({
      getInfo: function () {
        return post('device', 'getInfo', {});
      },
      getNetworkStatus: function () {
        return post('device', 'getNetworkStatus', {});
      },
      getBatteryStatus: function () {
        return post('device', 'getBatteryStatus', {});
      }
    }),
    storage: Object.freeze({
      get: function (key) {
        return post('storage', 'get', { key: key }).then(function (result) {
          return result.value;
        });
      },
      set: function (key, value) {
        return post('storage', 'set', { key: key, value: value });
      },
      remove: function (key) {
        return post('storage', 'remove', { key: key });
      },
      clear: function () {
        return post('storage', 'clear', {});
      }
    }),
    notification: Object.freeze({
      requestPermission: function () {
        return post('notification', 'requestPermission', {});
      },
      getPermissionStatus: function () {
        return post('notification', 'getPermissionStatus', {});
      },
      schedule: function (options) {
        return post('notification', 'schedule', options || {});
      },
      cancel: function (id) {
        return post('notification', 'cancel', { id: id });
      },
      cancelAll: function () {
        return post('notification', 'cancelAll', {});
      }
    }),
    secureStorage: Object.freeze({
      get: function (key) {
        return post('secureStorage', 'get', { key: key }).then(function (result) {
          return result.value;
        });
      },
      set: function (key, value) {
        return post('secureStorage', 'set', { key: key, value: value });
      },
      remove: function (key) {
        return post('secureStorage', 'remove', { key: key });
      },
      clear: function () {
        return post('secureStorage', 'clear', {});
      }
    }),
    network: Object.freeze({
      fetch: function (url, options) {
        return post('network', 'fetch', {
          url: url,
          options: options || {}
        });
      }
    }),
    app: Object.freeze({
      getManifest: function () {
        return post('app', 'getManifest', {});
      },
      getPermissions: function () {
        return post('app', 'getPermissions', {});
      },
      getCapabilities: function () {
        return post('app', 'getCapabilities', {});
      },
      getLocale: function () {
        return post('app', 'getLocale', {});
      },
      getTheme: function () {
        return post('app', 'getTheme', {});
      },
      getLifecycleState: function () {
        return post('app', 'getLifecycleState', {});
      }
    }),
    ui: Object.freeze({
      toast: function (message, options) {
        return post('ui', 'toast', { message: message, options: options || {} });
      },
      alert: function (options) {
        return post('ui', 'alert', options || {});
      },
      confirm: function (options) {
        return post('ui', 'confirm', options || {});
      },
      actionSheet: function (options) {
        return post('ui', 'actionSheet', options || {});
      },
      showLoading: function (options) {
        return post('ui', 'showLoading', options || {});
      },
      hideLoading: function () {
        return post('ui', 'hideLoading', {});
      }
    }),
    clipboard: Object.freeze({
      readText: function () {
        return post('clipboard', 'readText', {});
      },
      writeText: function (text) {
        return post('clipboard', 'writeText', { text: text });
      }
    }),
    share: Object.freeze({
      text: function (options) {
        return post('share', 'text', options || {});
      },
      files: function (options) {
        return post('share', 'files', options || {});
      }
    }),
    open: Object.freeze({
      url: function (url) {
        return post('open', 'url', { url: url });
      },
      phone: function (number) {
        return post('open', 'phone', { number: number });
      },
      email: function (options) {
        return post('open', 'email', options || {});
      },
      map: function (options) {
        return post('open', 'map', options || {});
      },
      settings: function () {
        return post('open', 'settings', {});
      }
    }),
    file: Object.freeze({
      pick: function (options) {
        return post('file', 'pick', options || {});
      },
      saveText: function (options) {
        return post('file', 'saveText', options || {});
      },
      saveBase64: function (options) {
        return post('file', 'saveBase64', options || {});
      },
      readBase64: function (path) {
        return post('file', 'readBase64', { path: path });
      },
      share: function (options) {
        return post('file', 'share', options || {});
      }
    }),
    media: Object.freeze({
      pickImage: function (options) {
        return post('media', 'pickImage', options || {});
      },
      pickVideo: function (options) {
        return post('media', 'pickVideo', options || {});
      },
      captureImage: function (options) {
        return post('media', 'captureImage', options || {});
      },
      captureVideo: function (options) {
        return post('media', 'captureVideo', options || {});
      },
      saveImage: function (options) {
        return post('media', 'saveImage', options || {});
      },
      saveVideo: function (options) {
        return post('media', 'saveVideo', options || {});
      }
    }),
    location: Object.freeze({
      getPermissionStatus: function () {
        return post('location', 'getPermissionStatus', {});
      },
      requestPermission: function () {
        return post('location', 'requestPermission', {});
      },
      getCurrentPosition: function (options) {
        return post('location', 'getCurrentPosition', options || {});
      }
    }),
    haptics: Object.freeze({
      selection: function () { return post('haptics', 'selection', {}); },
      light: function () { return post('haptics', 'light', {}); },
      medium: function () { return post('haptics', 'medium', {}); },
      heavy: function () { return post('haptics', 'heavy', {}); },
      success: function () { return post('haptics', 'success', {}); },
      warning: function () { return post('haptics', 'warning', {}); },
      error: function () { return post('haptics', 'error', {}); },
      vibrate: function () { return post('haptics', 'vibrate', {}); }
    }),
    barcode: Object.freeze({
      scan: function (options) {
        return post('barcode', 'scan', options || {});
      }
    }),
    audio: Object.freeze({
      requestPermission: function () {
        return post('audio', 'requestPermission', {});
      },
      startRecording: function (options) {
        return post('audio', 'startRecording', options || {});
      },
      stopRecording: function () {
        return post('audio', 'stopRecording', {});
      },
      play: function (options) {
        return post('audio', 'play', options || {});
      },
      stop: function () {
        return post('audio', 'stop', {});
      }
    }),
    biometric: Object.freeze({
      canAuthenticate: function () {
        return post('biometric', 'canAuthenticate', {});
      },
      authenticate: function (options) {
        return post('biometric', 'authenticate', options || {});
      }
    }),
    contacts: Object.freeze({
      requestPermission: function () {
        return post('contacts', 'requestPermission', {});
      },
      pick: function () {
        return post('contacts', 'pick', {});
      }
    }),
    calendar: Object.freeze({
      addEvent: function (options) {
        return post('calendar', 'addEvent', options || {});
      }
    }),
    download: Object.freeze({
      file: function (options) {
        return post('download', 'file', options || {});
      }
    }),
    events: Object.freeze({
      on: addListener
    })
  });
})();
