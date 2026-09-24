import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/bridge/tv_api.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/dev/tvvnc/tv_vnc/bridge/TvApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'dev.tvvnc.tv_vnc.bridge'),
))
enum CommandKind { key, keyDown, keyUp, sony, text, input, app, powerOn, powerOff,
  powerToggle, mute, unmute, volume, reboot, paste, editorAction }
enum Availability { unknown, advertised, needsSetup, permissionRequired, ready,
  unavailable, unsupported }
enum Delivery { notSent, rejected, sent, confirmed, unknown, queued }
enum MacroAction { wake, home, input, app, waitForTv, key, sony }

class MacroStep {
  MacroStep({required this.action, this.value, this.timeoutSeconds = 90});
  MacroAction action;
  String? value;
  int timeoutSeconds;
}
class TvMacro {
  TvMacro({required this.id, required this.name, required this.steps});
  String id;
  String name;
  List<MacroStep> steps;
}
class TvProfile {
  TvProfile({required this.id, required this.name, required this.host,
    this.vncPort = 5900, this.remotePort = 6466, this.pairingPort = 6467,
    this.mac, this.hasVncPassword = false, this.hasSonyKey = false,
    this.paired = false, required this.layout, required this.favorites,
    required this.recents, required this.macros, this.droidVnc = false, this.pointerVerified = false});
  String id;
  String name;
  String host;
  int vncPort;
  int remotePort;
  int pairingPort;
  String? mac;
  bool hasVncPassword;
  bool hasSonyKey;
  bool paired;
  List<String> layout;
  List<String> favorites;
  List<String> recents;
  List<TvMacro> macros;
  bool droidVnc;
  bool pointerVerified;
}
class TvCredentials {
  TvCredentials({this.vncPassword, this.sonyKey});
  String? vncPassword;
  String? sonyKey;
}
class DiscoveredTv {
  DiscoveredTv({required this.name, required this.host, required this.service, required this.port});
  String name;
  String host;
  String service;
  int port;
}
class TvButton {
  TvButton({required this.id, required this.name, this.androidCode,
    this.sonyCode, this.canHold = false, this.disruptive = false,
    this.state = Availability.unknown});
  String id;
  String name;
  int? androidCode;
  String? sonyCode;
  bool canHold;
  bool disruptive;
  Availability state;
}
class TvInput {
  TvInput({required this.uri, required this.name, this.label,
    this.connected = false, this.selected = false});
  String uri;
  String name;
  String? label;
  bool connected;
  bool selected;
}
class TvApplication {
  TvApplication({required this.id, required this.name, required this.uri,
    this.packageName, this.iconBytes});
  String id;
  String name;
  String uri;
  String? packageName;
  Uint8List? iconBytes;
}
class CapabilityInfo {
  CapabilityInfo({required this.id, required this.state, required this.transport,
    required this.observedAt, this.detail});
  String id;
  Availability state;
  String transport;
  int observedAt;
  String? detail;
}
class TransportInfo {
  TransportInfo({required this.id, required this.state, required this.observedAt,
    this.errorCode, this.latencyMs});
  String id;
  Availability state;
  int observedAt;
  String? errorCode;
  int? latencyMs;
}
class EditorInfo {
  EditorInfo({required this.application, required this.label, required this.text,
    required this.start, required this.end, required this.revision,
    this.inputType, this.imeOptions, this.actionId, this.actionLabel});
  String application;
  String label;
  String text;
  int start;
  int end;
  int revision;
  int? inputType;
  int? imeOptions;
  int? actionId;
  String? actionLabel;
}
class ScreenInfo {
  ScreenInfo({this.textureId, this.width = 0, this.height = 0,
    this.generation = 0, this.frameAt = 0, this.connected = false,
    this.stale = true, this.errorCode, this.desktopName, this.securityType,
    this.protocolVersion, this.extendedClipboard, this.hidden});
  int? textureId;
  int width;
  int height;
  int generation;
  int frameAt;
  bool connected;
  bool stale;
  String? errorCode;
  String? desktopName;
  int? securityType;
  String? protocolVersion;
  bool? extendedClipboard;
  bool? hidden;
}
class SessionSnapshot {
  SessionSnapshot({this.deviceId, this.sessionId = 0, this.power, this.currentInput, this.currentApp,
    this.volume, this.volumeMax, this.muted, this.model, this.firmware,
    this.remoteVersion, this.mac, this.editor, required this.screen,
    required this.transports, required this.capabilities, required this.buttons,
    required this.inputs, required this.apps, this.voiceState = 'idle',
    this.pairingState = 'idle', this.connectionStage = 'disconnected', this.macroId, this.macroStep, this.errorCode, this.sequence, this.networkPermissionGranted,
    this.volumeMin, this.volumeContext, this.volumeTarget});
  String? deviceId;
  int sessionId;
  String? power;
  String? currentInput;
  String? currentApp;
  int? volume;
  int? volumeMax;
  bool? muted;
  String? model;
  String? firmware;
  String? remoteVersion;
  String? mac;
  EditorInfo? editor;
  ScreenInfo screen;
  List<TransportInfo> transports;
  List<CapabilityInfo> capabilities;
  List<TvButton> buttons;
  List<TvInput> inputs;
  List<TvApplication> apps;
  String voiceState;
  String pairingState;
  String connectionStage;
  String? macroId;
  int? macroStep;
  String? errorCode;
  int? sequence;
  bool? networkPermissionGranted;
  int? volumeMin;
  String? volumeContext;
  String? volumeTarget;
}
class TvCommand {
  TvCommand({required this.deviceId, required this.sessionId, required this.kind, this.code, this.value, this.number,
    this.pressId, this.editorRevision, this.replaceText = false,
    this.userConfirmed = false, this.privateText = false, this.selectionStart, this.selectionEnd});
  String deviceId;
  int sessionId;
  CommandKind kind;
  int? code;
  String? value;
  int? number;
  String? pressId;
  int? editorRevision;
  bool replaceText;
  bool userConfirmed;
  bool privateText;
  int? selectionStart;
  int? selectionEnd;
}
class CommandOutcome {
  CommandOutcome({required this.delivery, this.transport, this.errorCode});
  Delivery delivery;
  String? transport;
  String? errorCode;
}

@HostApi()
abstract class TvHostApi {
  @async List<TvProfile> profiles();
  @async TvProfile saveProfile(TvProfile profile, TvCredentials? credentials);
  @async void forget(String deviceId);
  @async List<DiscoveredTv> discover();
  @async bool requestNetworkPermission();
  @async bool networkPermissionAllowed();
  @async void openSettings();
  @async SessionSnapshot connect(String deviceId);
  @async void disconnect(String deviceId, int sessionId);
  @async void pairRemote(String deviceId);
  @async void submitPairingCode(String deviceId, int sessionId, String code);
  @async void cancelPairing(String deviceId, int sessionId);
  @async bool registerSony(String deviceId, int sessionId, String? pin);
  @async Uint8List? applicationIcon(String deviceId, int sessionId, String appId);
  @async CommandOutcome execute(TvCommand command);
  @async ScreenInfo startScreen(String deviceId, int sessionId);
  @async void stopScreen(String deviceId, int sessionId);
  @async void screenDetail(String deviceId, int sessionId, bool fullResolution);
  @async void pointer(int x, int y, int buttons, int generation);
  @async String screenshot(String deviceId, int sessionId);
  @async void startVoice(String deviceId, int sessionId);
  @async void stopVoice(String deviceId, int sessionId);
  @async SessionSnapshot refresh(String deviceId, int sessionId);
  @async void reconnectTransport(String deviceId, int sessionId, String transport);
  @async String diagnosticReport(String deviceId, int sessionId);
  @async void runMacro(String deviceId, int sessionId, String macroId);
  @async void stopMacro(String deviceId, int sessionId);
}
@FlutterApi()
abstract class TvFlutterApi {
  void snapshotChanged(SessionSnapshot snapshot);
  void screenChanged(String deviceId, int sessionId, ScreenInfo screen);
}
