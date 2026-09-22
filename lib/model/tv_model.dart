import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../bridge/tv_api.g.dart';
import '../ui/copy.dart';

class TvTarget {
  const TvTarget(this.deviceId, this.sessionId);
  final String deviceId;
  final int sessionId;
}

typedef DraftContext = (String, String?);

class TvModel extends ChangeNotifier implements TvFlutterApi {
  TvModel({TvHostApi? api}) : api = api ?? TvHostApi();
  final TvHostApi api;
  final screen = ValueNotifier<ScreenInfo>(ScreenInfo());
  final remoteScreenHeight = ValueNotifier<double?>(null);
  final keyboardScreenHeight = ValueNotifier<double?>(null);
  List<TvProfile> profiles = [];
  TvProfile? selected;
  SessionSnapshot? state;
  String? message;
  int messageId = 0;
  bool loading = false;
  bool networkPermissionDenied = false;
  String? _nativeError;
  String? iconError;
  final _icons = <String, Future<Uint8List?>>{};
  final _drafts = <DraftContext, TextEditingValue>{};
  // A native editor can become known after Compose loaded. Keep the source key
  // across page recreation without moving or duplicating anyone's draft text.
  final _composeContexts = <DraftContext, DraftContext>{};
  int _deletionSequence = 0;
  int nextShortcutDeletion() => ++_deletionSequence;
  Future<void> _profileWrites = Future.value();
  Future<T?> _profileOperation<T>(Future<T> Function() operation) {
    final result = Completer<T?>();
    _profileWrites = _profileWrites.then((_) async {
      result.complete(await guard(operation));
    });
    return result.future;
  }

  DraftContext? get draftContext => selected == null
      ? null
      : (selected!.id, state?.editor?.application ?? state?.currentApp);
  TextEditingValue draft(DraftContext? context) =>
      _drafts[context] ?? TextEditingValue.empty;
  DraftContext? composeContextFor(DraftContext? context) =>
      _composeContexts[context] ?? context;
  void keepComposeContext(DraftContext? context, DraftContext? source) {
    if (context != null &&
        source != null &&
        context.$1 == source.$1 &&
        context != source &&
        _drafts.containsKey(source)) {
      _composeContexts[context] = source;
    }
  }

  void rememberDraft(DraftContext? context, TextEditingValue value) {
    if (context == null) return;
    if (value.text.isEmpty) {
      clearDraft(context);
    } else {
      _drafts[context] = value.copyWith(composing: TextRange.empty);
    }
  }

  void clearDraft(DraftContext? context) {
    _drafts.remove(context);
    _composeContexts.removeWhere((_, source) => source == context);
  }

  Future<Uint8List?> icon(TvApplication app) {
    final captured = target;
    if (captured == null) return Future.value(null);
    final key = '${captured.deviceId}:${captured.sessionId}:${app.id}';
    if (_icons.length > 128) _icons.remove(_icons.keys.first);
    return _icons.putIfAbsent(
      key,
      () => api
          .applicationIcon(captured.deviceId, captured.sessionId, app.id)
          .catchError((Object error) {
            if (_isCurrent(captured)) iconError = errorKey(error);
            return null;
          }),
    );
  }

  TvTarget? get target =>
      state?.deviceId == selected?.id && state?.deviceId != null
      ? TvTarget(state!.deviceId!, state!.sessionId)
      : null;

  Future<void> initialize() async {
    TvFlutterApi.setUp(this);
    await reload();
  }

  Future<void> reload() async {
    profiles = await api.profiles();
    if (selected != null) {
      selected = profiles.where((p) => p.id == selected!.id).firstOrNull;
    }
    notifyListeners();
  }

  void report(String key) {
    message = Copy.text(key);
    messageId++;
    notifyListeners();
  }

  bool _isCurrent(TvTarget origin) =>
      target?.deviceId == origin.deviceId &&
      target?.sessionId == origin.sessionId;

  Future<T?> guard<T>(
    Future<T> Function() operation, {
    TvTarget? origin,
  }) async {
    try {
      return await operation();
    } catch (error) {
      if (origin == null || _isCurrent(origin)) report(errorKey(error));
      return null;
    }
  }

  Future<void> connect(TvProfile profile) async {
    final previous = target;
    selected = profile;
    state = null;
    _icons.clear();
    screen.value = ScreenInfo();
    loading = true;
    notifyListeners();
    await guard(() async {
      if (previous != null) {
        await api.disconnect(previous.deviceId, previous.sessionId);
      }
      if (!await requestNetworkAccess()) {
        report('permissionBody');
        return;
      }
      if (selected?.id != profile.id) return;
      final snapshot = await api.connect(profile.id);
      if (selected?.id == profile.id) snapshotChanged(snapshot);
    });
    loading = false;
    notifyListeners();
  }

  Future<bool> requestNetworkAccess() async {
    final allowed = await api.requestNetworkPermission();
    networkPermissionDenied = !allowed;
    notifyListeners();
    return allowed;
  }

  Future<void> refreshNetworkAccess() async {
    networkPermissionDenied = !await api.networkPermissionAllowed();
    notifyListeners();
  }

  Future<void> disconnect() async {
    final origin = target;
    if (origin != null) {
      await guard(() => api.disconnect(origin.deviceId, origin.sessionId));
    }
  }

  Future<TvProfile?> save(TvProfile profile, TvCredentials? credentials) =>
      _profileOperation(() async {
        final saved = await api.saveProfile(profile, credentials);
        await reload();
        return saved;
      });
  Future<void> forget(TvProfile profile) async {
    await _profileOperation(() async {
      await api.forget(profile.id);
      profiles = profiles.where((p) => p.id != profile.id).toList();
      if (selected?.id == profile.id) {
        selected = null;
        state = null;
        screen.value = ScreenInfo();
      }
      // Let editor listeners leave their old context before clearing its cache.
      notifyListeners();
      _drafts.removeWhere((key, _) => key.$1 == profile.id);
      _composeContexts.removeWhere((key, _) => key.$1 == profile.id);
      await reload();
    });
  }

  Future<TvProfile?> updateSaved(
    String id,
    TvProfile? Function(TvProfile) edit,
  ) => _profileOperation<TvProfile?>(() async {
    final latest = (await api.profiles()).where((p) => p.id == id).firstOrNull;
    if (latest == null) return null; // Never recreate a forgotten TV.
    final changed = edit(latest);
    if (changed == null) return null;
    final saved = await api.saveProfile(changed, null);
    await reload();
    return saved;
  });

  Future<CommandOutcome?> command(
    CommandKind kind, {
    TvTarget? origin,
    int? code,
    String? value,
    int? number,
    String? pressId,
    int? editorRevision,
    bool replaceText = false,
    bool privateText = false,
    bool confirmed = false,
  }) async {
    final captured = origin ?? target;
    if (captured == null) {
      report('notSent');
      return null;
    }
    return guard(() async {
      final result = await api.execute(
        TvCommand(
          deviceId: captured.deviceId,
          sessionId: captured.sessionId,
          kind: kind,
          code: code,
          value: value,
          number: number,
          pressId: pressId,
          editorRevision: editorRevision,
          replaceText: replaceText,
          privateText: privateText,
          userConfirmed: confirmed,
        ),
      );
      if (!_isCurrent(captured)) return result;
      if (kind == CommandKind.text &&
          editorRevision != null &&
          state?.editor?.revision != editorRevision) {
        return result;
      }
      if (result.delivery == Delivery.unknown) {
        report(
          kind == CommandKind.text ? 'textUnconfirmed' : 'commandUnconfirmed',
        );
      }
      if (kind == CommandKind.text &&
          !replaceText &&
          result.delivery == Delivery.sent) {
        report('textUnconfirmed');
      }
      if (result.delivery == Delivery.notSent ||
          result.delivery == Delivery.rejected) {
        report(codeKey(result.errorCode));
      }
      if (kind == CommandKind.app && result.delivery == Delivery.sent) {
        await reload();
      }
      return result;
    }, origin: captured);
  }

  Future<void> onTarget(Future<void> Function(TvTarget) operation) async {
    final origin = target;
    if (origin != null) await guard(() => operation(origin), origin: origin);
  }

  Future<void> favorite(TvApplication app) async {
    final profile = selected;
    if (profile == null) return;
    await updateSaved(profile.id, (latest) {
      final favorites = [...latest.favorites];
      favorites.contains(app.id)
          ? favorites.remove(app.id)
          : favorites.add(app.id);
      return latest.updated(favorites: favorites);
    });
  }

  bool has(String id) =>
      state?.capabilities.any(
        (c) => c.id == id && c.state == Availability.ready,
      ) ==
      true;
  @override
  void snapshotChanged(SessionSnapshot snapshot) {
    if (snapshot.deviceId != selected?.id ||
        snapshot.sessionId < (state?.sessionId ?? 0)) {
      return;
    }
    final sameSession = state?.sessionId == snapshot.sessionId;
    if (sameSession && (snapshot.sequence ?? 0) < (state?.sequence ?? 0)) {
      return;
    }
    state = snapshot;
    if (snapshot.networkPermissionGranted != null) {
      networkPermissionDenied = !snapshot.networkPermissionGranted!;
    }
    if (selected?.mac == null && snapshot.mac != null) {
      selected!.mac = snapshot.mac;
    }
    if (!sameSession ||
        snapshot.connectionStage == 'disconnected' ||
        snapshot.screen.generation >= screen.value.generation) {
      screen.value = snapshot.screen;
    }
    if (snapshot.errorCode != null && snapshot.errorCode != _nativeError) {
      message = Copy.text(codeKey(snapshot.errorCode));
      messageId++;
    }
    _nativeError = snapshot.errorCode;
    notifyListeners();
  }

  @override
  void screenChanged(String deviceId, int sessionId, ScreenInfo next) {
    if (deviceId == selected?.id &&
        sessionId == state?.sessionId &&
        state?.connectionStage != 'disconnected' &&
        next.generation >= screen.value.generation) {
      screen.value = next;
    }
  }

  @override
  void dispose() {
    TvFlutterApi.setUp(null);
    _drafts.clear();
    _composeContexts.clear();
    screen.dispose();
    remoteScreenHeight.dispose();
    keyboardScreenHeight.dispose();
    super.dispose();
  }

  static String errorKey(Object error) =>
      codeKey(error is PlatformException ? error.message : null);
  static String codeKey(String? code) => switch (code) {
    'network_permission' => 'permissionBody',
    'authentication_required' => 'authFailed',
    'pairing_required' => 'pairingRequired',
    'pairing_rejected' => 'pairingFailed',
    'secure_connection_failed' => 'secureConnectionFailed',
    'pairing_unavailable' || 'pairing_protocol_error' => 'pairingUnavailable',
    'pairing_timeout' => 'pairingTimedOut',
    'identity_changed' => 'identityChanged',
    'non_local_address' || 'invalid_address' => 'privateOnly',
    'invalid_port' => 'invalidPort',
    'invalid_mac' => 'invalidMac',
    'unsupported' => 'unsupported',
    'editor_changed' => 'editorChanged',
    'no_editor' => 'noEditor',
    'delivery_unknown' => 'commandUnconfirmed',
    'voice_not_ready' => 'voiceNotReady',
    'microphone_ready' => 'micPermission',
    'microphone_unavailable' ||
    'microphone_permission' => 'microphoneUnavailable',
    'macro_failed' => 'shortcutFailed',
    'wake_unconfirmed' => 'commandTimeout',
    'standby' => 'powerOffFirst',
    'not_connected' => 'notConnected',
    'remote_rejected' => 'commandUnconfirmed',
    'message_too_large' || 'text_too_large' => 'tooMuchText',
    'invalid_command' => 'notSent',
    'screen_unavailable' => 'screenUnavailable',
    'secure_storage_failed' ||
    'credential_storage_failed' ||
    'credential_storage_invalid' ||
    'profile_storage_failed' ||
    'exportable_identity' ||
    'pin_storage_failed' ||
    'identity_storage_failed' => 'storageFailed',
    'timeout' || 'remote_write_timeout' => 'timeoutFailure',
    'connection_refused' => 'connectionRefused',
    'address_unresolved' => 'addressUnresolved',
    'network_route_unavailable' => 'networkRouteUnavailable',
    'invalid_frame' => 'screenInvalid',
    'frame_too_large' => 'screenTooLarge',
    'surface_unavailable' => 'screenSurfaceFailure',
    'registration_unconfirmed' => 'registrationUnconfirmed',
    'transport_unavailable' ||
    'remote_disconnected' ||
    'voice_disconnected' => 'transportUnavailable',
    'invalid_link' => 'invalidLink',
    'confirmation_required' => 'confirmationRequired',
    'network_changed' => 'networkChanged',
    'stale_session' || 'press_missing' => 'notSent',
    _ => 'connectionFailed',
  };
}

extension ProfileEdits on TvProfile {
  TvProfile updated({
    List<String>? favorites,
    List<String>? layout,
    List<TvMacro>? macros,
    bool? droidVnc,
    bool? pointerVerified,
  }) => TvProfile(
    id: id,
    name: name,
    host: host,
    vncPort: vncPort,
    remotePort: remotePort,
    pairingPort: pairingPort,
    mac: mac,
    hasVncPassword: hasVncPassword,
    hasSonyKey: hasSonyKey,
    paired: paired,
    layout: layout ?? this.layout,
    favorites: favorites ?? this.favorites,
    recents: recents,
    macros: macros ?? this.macros,
    droidVnc: droidVnc ?? this.droidVnc,
    pointerVerified: pointerVerified ?? this.pointerVerified,
  );
}
