(function () {
  const $ = (id) => document.getElementById(id);

  const elements = {
    missionId: $('missionId'),
    runtimeStatus: $('runtimeStatus'),
    healthScore: $('healthScore'),
    healthText: $('healthText'),
    passCount: $('passCount'),
    failCount: $('failCount'),
    locationText: $('locationText'),
    incidentTitle: $('incidentTitle'),
    incidentNote: $('incidentNote'),
    logList: $('logList'),
    runSafeButton: $('runSafeButton'),
    runAllButton: $('runAllButton'),
    clearButton: $('clearButton')
  };

  const missionId = 'PATROL-' + new Date().toISOString().slice(5, 10).replace('-', '') + '-' + Math.floor(1000 + Math.random() * 9000);
  const state = {
    missionId: missionId,
    incidentTitle: elements.incidentTitle.value,
    incidentNote: elements.incidentNote.value,
    lastLocation: null,
    contact: null,
    savedFiles: [],
    audioPath: null,
    eventSubscribed: false
  };
  const stats = { pass: 0, fail: 0 };
  const eventUnsubscribers = [];

  const safeTests = [
    'appInfo',
    'deviceInfo',
    'saveIncident',
    'secureAccess',
    'clipboardBrief',
    'hapticsSuite',
    'eventsToggle',
    'networkFetch'
  ];

  const allTests = [
    'appInfo',
    'deviceInfo',
    'saveIncident',
    'secureAccess',
    'uiFlow',
    'clipboardBrief',
    'shareBrief',
    'hapticsSuite',
    'eventsToggle',
    'networkFetch',
    'fileEvidence',
    'pickFile',
    'pickImage',
    'pickVideo',
    'captureImage',
    'captureVideo',
    'scanAsset',
    'audioStart',
    'audioStop',
    'locationFix',
    'contactDispatch',
    'calendarFollowup',
    'notificationPlan',
    'downloadChecklist',
    'biometricGate',
    'openExternal'
  ];

  const tests = {
    appInfo: async function () {
      const result = {
        manifest: await AppRuntime.app.getManifest(),
        permissions: await AppRuntime.app.getPermissions(),
        capabilities: await AppRuntime.app.getCapabilities(),
        locale: await AppRuntime.app.getLocale(),
        theme: await AppRuntime.app.getTheme(),
        lifecycle: await AppRuntime.app.getLifecycleState()
      };
      elements.runtimeStatus.textContent = '运行时 ' + (result.manifest.runtimeVersion || AppRuntime.runtimeVersion || '1.0');
      return result;
    },

    deviceInfo: async function () {
      return {
        info: await AppRuntime.device.getInfo(),
        network: await AppRuntime.device.getNetworkStatus(),
        battery: await AppRuntime.device.getBatteryStatus()
      };
    },

    saveIncident: async function () {
      syncIncidentFields();
      const payload = {
        missionId: state.missionId,
        title: state.incidentTitle,
        note: state.incidentNote,
        updatedAt: new Date().toISOString(),
        lastLocation: state.lastLocation,
        contact: state.contact
      };
      await AppRuntime.storage.set('current-incident', payload);
      await AppRuntime.storage.set('scratch', { removable: true });
      await AppRuntime.storage.remove('scratch');
      return {
        saved: payload,
        loaded: await AppRuntime.storage.get('current-incident')
      };
    },

    secureAccess: async function () {
      const accessCode = 'zone-' + missionId.toLowerCase();
      await AppRuntime.secureStorage.set('field-access-code', accessCode);
      const loaded = await AppRuntime.secureStorage.get('field-access-code');
      return {
        stored: loaded === accessCode,
        masked: loaded ? loaded.slice(0, 4) + '...' + loaded.slice(-4) : null
      };
    },

    uiFlow: async function () {
      await AppRuntime.ui.showLoading({ message: '正在模拟上报巡检任务...' });
      await delay(650);
      await AppRuntime.ui.hideLoading();
      await AppRuntime.ui.toast('巡检台 UI bridge 已连接');
      await AppRuntime.ui.alert({
        title: '现场提示',
        message: '下一步会打开确认框和行动菜单。',
        buttonText: '继续'
      });
      const confirm = await AppRuntime.ui.confirm({
        title: '是否启动应急巡检？',
        message: state.incidentTitle,
        confirmText: '启动',
        cancelText: '稍后'
      });
      const action = await AppRuntime.ui.actionSheet({
        options: ['设为高优先级', '请求支援', '记录为观察', '取消']
      });
      return { confirm: confirm, actionSheet: action };
    },

    clipboardBrief: async function () {
      const brief = buildBrief();
      await AppRuntime.clipboard.writeText(brief);
      const readBack = await AppRuntime.clipboard.readText();
      return {
        copied: brief,
        readBack: readBack
      };
    },

    shareBrief: async function () {
      return await AppRuntime.share.text({
        title: '城市应急巡检简报',
        subject: state.missionId,
        text: buildBrief()
      });
    },

    hapticsSuite: async function () {
      await AppRuntime.haptics.selection();
      await AppRuntime.haptics.light();
      await AppRuntime.haptics.medium();
      await AppRuntime.haptics.heavy();
      await AppRuntime.haptics.success();
      await AppRuntime.haptics.warning();
      await AppRuntime.haptics.error();
      await AppRuntime.haptics.vibrate();
      return { sequence: ['selection', 'light', 'medium', 'heavy', 'success', 'warning', 'error', 'vibrate'] };
    },

    eventsToggle: async function () {
      if (state.eventSubscribed) {
        while (eventUnsubscribers.length) {
          eventUnsubscribers.pop()();
        }
        state.eventSubscribed = false;
        return { subscribed: false };
      }

      ['resumed', 'inactive', 'paused', 'detached', 'hidden', 'subscription'].forEach(function (type) {
        const unsubscribe = AppRuntime.events.on(type, function (payload) {
          addLog('event.' + type, true, payload, { countStats: false });
        });
        eventUnsubscribers.push(unsubscribe);
      });
      state.eventSubscribed = true;
      return { subscribed: true, types: ['resumed', 'inactive', 'paused', 'detached', 'hidden', 'subscription'] };
    },

    networkFetch: async function () {
      const response = await AppRuntime.network.fetch('https://example.com', {
        method: 'GET',
        headers: { accept: 'text/html' }
      });
      return {
        status: response.status,
        headers: response.headers,
        preview: String(response.body || '').slice(0, 180)
      };
    },

    fileEvidence: async function () {
      const report = buildBrief() + '\n\n审计时间：' + new Date().toISOString();
      const saved = await AppRuntime.file.saveText({
        fileName: 'patrol-report-' + state.missionId + '.txt',
        text: report
      });
      const savedPath = getFilePath(saved);
      const readBack = savedPath ? await AppRuntime.file.readBase64(savedPath) : null;
      const snapshot = await AppRuntime.file.saveBase64({
        fileName: 'patrol-snapshot.json',
        base64: toBase64(JSON.stringify(state, null, 2))
      });
      const snapshotPath = getFilePath(snapshot);
      if (savedPath) {
        state.savedFiles.push(savedPath);
        await AppRuntime.share.files({
          paths: [savedPath],
          title: '巡检报告',
          text: '请查看巡检报告'
        });
      }
      if (snapshotPath) {
        state.savedFiles.push(snapshotPath);
        await AppRuntime.file.share({
          paths: [snapshotPath],
          title: '巡检状态快照'
        });
      }
      return {
        saved: saved,
        readBackPreview: readBack ? String(readBack.base64 || '').slice(0, 80) : null,
        snapshot: snapshot
      };
    },

    pickFile: async function () {
      const picked = await AppRuntime.file.pick({ allowMultiple: false });
      const firstPath = picked.files && picked.files[0] && picked.files[0].path;
      return {
        picked: picked,
        readBack: firstPath ? await AppRuntime.file.readBase64(firstPath) : null
      };
    },

    pickImage: async function () {
      return await AppRuntime.media.pickImage({ quality: 82 });
    },

    pickVideo: async function () {
      return await AppRuntime.media.pickVideo({});
    },

    captureImage: async function () {
      return await AppRuntime.media.captureImage({ quality: 82 });
    },

    captureVideo: async function () {
      return await AppRuntime.media.captureVideo({});
    },

    scanAsset: async function () {
      const result = await AppRuntime.barcode.scan({ title: '扫描现场设备码' });
      state.assetCode = result.value;
      await AppRuntime.storage.set('last-asset-code', result.value);
      return result;
    },

    audioStart: async function () {
      const permission = await AppRuntime.audio.requestPermission();
      const recording = await AppRuntime.audio.startRecording({ fileName: 'patrol-audio.m4a' });
      state.audioPath = recording.path;
      return { permission: permission, recording: recording };
    },

    audioStop: async function () {
      const stopped = await AppRuntime.audio.stopRecording();
      const filePath = getFilePath(stopped) || state.audioPath;
      if (filePath) {
        state.audioPath = filePath;
        await AppRuntime.audio.play({ path: filePath });
        await delay(900);
        await AppRuntime.audio.stop();
      }
      return { stopped: stopped, played: Boolean(filePath) };
    },

    locationFix: async function () {
      const before = await AppRuntime.location.getPermissionStatus();
      const requested = await AppRuntime.location.requestPermission();
      const position = await AppRuntime.location.getCurrentPosition({ timeoutSeconds: 15 });
      state.lastLocation = position;
      elements.locationText.textContent = Number(position.latitude).toFixed(4) + ', ' + Number(position.longitude).toFixed(4);
      const opened = await AppRuntime.open.map({
        latitude: position.latitude,
        longitude: position.longitude,
        label: state.incidentTitle
      });
      return { before: before, requested: requested, position: position, openedMap: opened };
    },

    contactDispatch: async function () {
      const permission = await AppRuntime.contacts.requestPermission();
      const picked = await AppRuntime.contacts.pick();
      state.contact = picked.contact;
      await AppRuntime.storage.set('dispatch-contact', picked.contact);
      return { permission: permission, contact: picked.contact };
    },

    calendarFollowup: async function () {
      const start = new Date(Date.now() + 30 * 60 * 1000);
      const end = new Date(start.getTime() + 30 * 60 * 1000);
      return await AppRuntime.calendar.addEvent({
        title: '复查：' + state.incidentTitle,
        description: buildBrief(),
        location: state.lastLocation ? state.lastLocation.latitude + ',' + state.lastLocation.longitude : '城市应急巡检点',
        startTime: start.toISOString(),
        endTime: end.toISOString()
      });
    },

    notificationPlan: async function () {
      const permission = await AppRuntime.notification.requestPermission();
      const status = await AppRuntime.notification.getPermissionStatus();
      const id = 4207;
      const scheduled = await AppRuntime.notification.schedule({
        id: id,
        title: '巡检复查提醒',
        body: state.incidentTitle,
        time: new Date(Date.now() + 60 * 1000).toISOString()
      });
      const cancelled = await AppRuntime.notification.cancel(id);
      const cancelledAll = await AppRuntime.notification.cancelAll();
      return {
        permission: permission,
        status: status,
        scheduled: scheduled,
        cancelled: cancelled,
        cancelledAll: cancelledAll
      };
    },

    downloadChecklist: async function () {
      const downloaded = await AppRuntime.download.file({
        url: 'https://example.com',
        fileName: 'emergency-checklist.html'
      });
      const path = getFilePath(downloaded);
      if (path) {
        state.savedFiles.push(path);
      }
      return downloaded;
    },

    biometricGate: async function () {
      const capability = await AppRuntime.biometric.canAuthenticate();
      if (!capability.isDeviceSupported) {
        return { capability: capability, authenticated: false };
      }
      const auth = await AppRuntime.biometric.authenticate({
        reason: '确认提交城市应急巡检记录'
      });
      return { capability: capability, auth: auth };
    },

    openExternal: async function () {
      const accepted = await AppRuntime.ui.confirm({
        title: '即将打开外部应用',
        message: '此项会依次触发 URL、电话、邮件和系统设置，用于验证 open bridge。',
        confirmText: '继续',
        cancelText: '只打开网页'
      });
      const result = {
        url: await AppRuntime.open.url('https://example.com'),
        map: state.lastLocation ? await AppRuntime.open.map({
          latitude: state.lastLocation.latitude,
          longitude: state.lastLocation.longitude,
          label: state.incidentTitle
        }) : null
      };
      if (accepted.accepted) {
        result.phone = await AppRuntime.open.phone('10086');
        result.email = await AppRuntime.open.email({
          to: 'ops@example.com',
          subject: state.missionId,
          body: buildBrief()
        });
        result.settings = await AppRuntime.open.settings();
      }
      return result;
    }
  };

  function syncIncidentFields() {
    state.incidentTitle = elements.incidentTitle.value.trim() || '未命名巡检任务';
    state.incidentNote = elements.incidentNote.value.trim();
  }

  function buildBrief() {
    syncIncidentFields();
    const location = state.lastLocation
      ? Number(state.lastLocation.latitude).toFixed(6) + ', ' + Number(state.lastLocation.longitude).toFixed(6)
      : '未定位';
    const contact = state.contact ? state.contact.displayName : '未指派';
    const asset = state.assetCode || '未扫描';
    return [
      '【城市应急巡检】' + state.missionId,
      '主题：' + state.incidentTitle,
      '摘要：' + state.incidentNote,
      '位置：' + location,
      '联系人：' + contact,
      '设备码：' + asset
    ].join('\n');
  }

  function updateStats() {
    const total = stats.pass + stats.fail;
    const score = total === 0 ? 0 : Math.round((stats.pass / total) * 100);
    elements.passCount.textContent = String(stats.pass);
    elements.failCount.textContent = String(stats.fail);
    elements.healthScore.textContent = score + '%';
    elements.healthText.textContent = total === 0 ? '尚未执行验证' : '已执行 ' + total + ' 次 bridge 调用';
  }

  function addLog(name, ok, payload, options) {
    const countStats = !options || options.countStats !== false;
    if (countStats) {
      stats[ok ? 'pass' : 'fail'] += 1;
      updateStats();
    }

    const empty = elements.logList.querySelector('.empty');
    if (empty) {
      empty.remove();
    }

    const item = document.createElement('article');
    item.className = 'log-item ' + (ok ? 'pass' : 'fail');
    item.innerHTML =
      '<div class="log-head">' +
      '<span class="log-title">' + escapeHtml(name) + '</span>' +
      '<span class="badge">' + (ok ? 'PASS' : 'FAIL') + '</span>' +
      '</div>' +
      '<pre>' + escapeHtml(formatPayload(payload)) + '</pre>';
    elements.logList.prepend(item);
  }

  function formatPayload(value) {
    try {
      return JSON.stringify(value, null, 2);
    } catch (error) {
      return String(value);
    }
  }

  function normalizeError(error) {
    return {
      code: error && error.code ? error.code : 'ERROR',
      message: error && error.message ? error.message : String(error)
    };
  }

  function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, function (char) {
      return ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
      })[char];
    });
  }

  function delay(ms) {
    return new Promise(function (resolve) {
      window.setTimeout(resolve, ms);
    });
  }

  function toBase64(value) {
    return window.btoa(unescape(encodeURIComponent(value)));
  }

  function getFilePath(result) {
    if (!result || !result.file) {
      return null;
    }
    return result.file.path || null;
  }

  async function runTest(name) {
    const test = tests[name];
    if (!test) {
      addLog(name, false, { message: '未知测试项' });
      return;
    }
    try {
      const result = await test();
      addLog(name, true, result);
    } catch (error) {
      addLog(name, false, normalizeError(error));
    }
  }

  async function runSequence(names, button) {
    button.disabled = true;
    try {
      for (const name of names) {
        await runTest(name);
      }
    } finally {
      button.disabled = false;
    }
  }

  document.querySelectorAll('[data-test]').forEach(function (button) {
    button.addEventListener('click', function () {
      runTest(button.getAttribute('data-test'));
    });
  });

  elements.runSafeButton.addEventListener('click', function () {
    runSequence(safeTests, elements.runSafeButton);
  });

  elements.runAllButton.addEventListener('click', function () {
    runSequence(allTests, elements.runAllButton);
  });

  elements.clearButton.addEventListener('click', function () {
    stats.pass = 0;
    stats.fail = 0;
    updateStats();
    elements.logList.innerHTML = '<p class="empty">还没有 bridge 调用记录。</p>';
  });

  async function bootstrap() {
    elements.missionId.textContent = missionId;
    elements.logList.innerHTML = '<p class="empty">还没有 bridge 调用记录。</p>';
    updateStats();
    if (!window.AppRuntime) {
      elements.runtimeStatus.textContent = '未检测到 AppRuntime';
      return;
    }
    elements.runtimeStatus.textContent = 'AppRuntime 已注入';
    try {
      const previous = await AppRuntime.storage.get('current-incident');
      if (previous && previous.title) {
        elements.incidentTitle.value = previous.title;
        elements.incidentNote.value = previous.note || elements.incidentNote.value;
        state.lastLocation = previous.lastLocation || null;
        state.contact = previous.contact || null;
      }
    } catch (error) {
      addLog('bootstrap.storage', false, normalizeError(error));
    }
  }

  bootstrap();
})();
