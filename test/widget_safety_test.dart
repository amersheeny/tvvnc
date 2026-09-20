import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/model/tv_model.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';
import 'package:tv_vnc/ui/catalog_pages.dart';
import 'package:tv_vnc/ui/remote_page.dart';
import 'package:tv_vnc/ui/shortcuts_page.dart';
import 'package:tv_vnc/ui/viewer.dart';
import 'package:tv_vnc/ui/widgets.dart';
import 'package:tv_vnc/ui/copy.dart';

class RecordingApi extends TvHostApi {
  final commands = <TvCommand>[];
  final pointers = <(int, int, int, int)>[];
  int voiceStarts = 0;
  int voiceStops = 0;
  final voiceTargets = <(String, int)>[];
  final iconRequests = <String>[];
  @override
  Future<Uint8List?> applicationIcon(
    String deviceId,
    int sessionId,
    String appId,
  ) async {
    iconRequests.add(appId);
    return null;
  }

  @override
  Future<void> startVoice(String deviceId, int sessionId) async {
    voiceStarts++;
    voiceTargets.add((deviceId, sessionId));
  }

  @override
  Future<void> stopVoice(String deviceId, int sessionId) async {
    voiceStops++;
  }

  @override
  Future<void> pointer(int x, int y, int buttons, int generation) async {
    pointers.add((x, y, buttons, generation));
  }

  @override
  Future<void> screenDetail(
    String deviceId,
    int sessionId,
    bool fullResolution,
  ) async {}
  Completer<CommandOutcome>? delayed;
  @override
  Future<CommandOutcome> execute(TvCommand command) async {
    commands.add(command);
    return delayed?.future ??
        CommandOutcome(delivery: Delivery.sent, transport: 'test');
  }
}

class SavedApi extends RecordingApi {
  final saved = <String, TvProfile>{};
  int saves = 0;
  @override
  Future<List<TvProfile>> profiles() async => List.unmodifiable(saved.values);
  @override
  Future<TvProfile> saveProfile(
    TvProfile profile,
    TvCredentials? credentials,
  ) async {
    saves++;
    saved[profile.id] = profile;
    return profile;
  }

  @override
  Future<void> forget(String deviceId) async {
    saved.remove(deviceId);
  }
}

TvProfile profile(String id) => TvProfile(
  id: id,
  name: id,
  host: '192.168.1.2',
  layout: [],
  favorites: [],
  recents: [],
  macros: [],
);
SessionSnapshot snapshot(String device, int session, {int revision = 1}) =>
    SessionSnapshot(
      deviceId: device,
      sessionId: session,
      screen: ScreenInfo(),
      connectionStage: 'connected',
      transports: [],
      capabilities: [],
      inputs: [],
      apps: [],
      editor: EditorInfo(
        application: 'test.app',
        label: 'Search',
        text: '',
        start: 0,
        end: 0,
        revision: revision,
      ),
      buttons: [
        TvButton(id: 'home', name: 'Home', androidCode: 3, canHold: true),
      ],
    );
TvModel model(RecordingApi api) {
  final m = TvModel(api: api)..selected = profile('a');
  m.snapshotChanged(snapshot('a', 1));
  return m;
}

void main() {
  testWidgets('late phone paste cannot replace a cleared and retyped buffer', (
    tester,
  ) async {
    final clipboard = Completer<Map<String, String>>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? clipboard.future : null,
    );
    final m = model(RecordingApi());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.tap(find.text('Private text'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'same text');
    await tester.tap(find.text('Private text'));
    await tester.pump();
    await tester.tap(find.text('Paste'));
    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'same text');
    clipboard.complete({'text': 'late protected clipboard'});
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'same text',
    );
    expect(m.draft(('a', 'test.app')).text, 'same text');
    await tester.pumpWidget(const SizedBox());
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
    m.dispose();
  });
  testWidgets(
    'unavailable control keeps its full width and marker hit target',
    (tester) async {
      final m = model(RecordingApi());
      m.state!.buttons.single.state = Availability.unavailable;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: RemoteButton(
                model: m,
                code: 3,
                label: 'Home',
                icon: Icons.home,
              ),
            ),
          ),
        ),
      );
      final button = find.byType(FilledButton);
      expect(tester.getSize(button).width, 500);
      await tester.tapAt(tester.getCenter(find.byIcon(Icons.info_outline)));
      await tester.pumpAndSettle();
      expect(find.text(t('controlUnavailable')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets('revealed private text never becomes an ordinary cached draft', (
    tester,
  ) async {
    final m = model(RecordingApi());
    Widget page() => MaterialApp(home: Scaffold(body: KeyboardPage(m)));
    await tester.pumpWidget(page());
    await tester.tap(find.text('Private text'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'private fixture');
    await tester.tap(find.text('Private text'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'private fixture',
    );
    expect(m.draft(('a', 'test.app')).text, isEmpty);
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.enableIMEPersonalizedLearning, isFalse);
    expect(editor.enableSuggestions, isFalse);
    expect(find.byType(ExpansionTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page());
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets(
    'clearing a revealed sensitive buffer restores ordinary input with a new client',
    (tester) async {
      final m = model(RecordingApi());
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.tap(find.text('Private text'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'private fixture');
      await tester.tap(find.text('Private text'));
      await tester.pump();
      final clients = tester.testTextInput.log
          .where((c) => c.method == 'TextInput.setClient')
          .length;
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(
        tester.testTextInput.log
            .where((c) => c.method == 'TextInput.setClient')
            .length,
        greaterThan(clients),
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .enableIMEPersonalizedLearning,
        isTrue,
      );
      await tester.enterText(find.byType(TextField), 'ordinary again');
      expect(m.draft(('a', 'test.app')).text, 'ordinary again');
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets('late phone paste cannot cross a privacy transition', (
    tester,
  ) async {
    final clipboard = Completer<Map<String, String>>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? clipboard.future : null,
    );
    final m = model(RecordingApi());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.tap(find.text('Private text'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'current private');
    await tester.tap(find.text('Paste'));
    await tester.tap(find.text('Private text'));
    await tester.pump();
    clipboard.complete({'text': 'late private clipboard'});
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'current private',
    );
    expect(m.draft(('a', 'test.app')).text, isEmpty);
    await tester.pumpWidget(const SizedBox());
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
    m.dispose();
  });
  test('copy interpolation never interprets placeholder-like user names', () {
    expect(
      Copy.format('shortcutDeletionContext', {
        'number': '2',
        'tv': '{number} TV',
      }),
      'Deletion 2 · {number} TV',
    );
  });
  for (final dismissFirst in [false, true]) {
    testWidgets(
      'same-name Undo records remain distinct; dismissFirst=$dismissFirst',
      (tester) async {
        final api = SavedApi();
        final first = TvMacro(
          id: 'first',
          name: 'Same name',
          steps: [MacroStep(action: MacroAction.home)],
        );
        final second = TvMacro(
          id: 'second',
          name: 'Same name',
          steps: [MacroStep(action: MacroAction.key, value: '24')],
        );
        api.saved['a'] = profile('a').updated(macros: [first, second]);
        final m = model(api)..selected = api.saved['a'];
        await tester.pumpWidget(
          MaterialApp(
            home: AnimatedBuilder(
              animation: m,
              builder: (_, _) => Scaffold(body: ShortcutsPage(m)),
            ),
          ),
        );
        await tester.tap(find.byTooltip('Delete').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Delete').first);
        await tester.pumpAndSettle();
        expect(find.text('Deletion 1 · a'), findsOneWidget);
        expect(find.text('Deletion 2 · a'), findsNothing);
        if (dismissFirst) {
          await tester.tap(find.byTooltip('Dismiss'));
        } else {
          await tester.tap(find.text('Undo'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Deletion 2 · a'), findsOneWidget);
        expect(
          api.saved['a']!.macros.map((m) => m.id),
          dismissFirst ? isEmpty : ['first'],
        );
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(
          api.saved['a']!.macros.map((m) => m.id),
          dismissFirst ? ['second'] : ['first', 'second'],
        );
        expect(api.saved['a']!.macros.last.steps.single.value, '24');
        expect(find.byType(SnackBar), findsNothing);
        await tester.pumpWidget(const SizedBox());
        m.dispose();
      },
    );
  }
  testWidgets(
    'failed live edit restores Compose without overwriting its draft',
    (tester) async {
      final api = RecordingApi()..delayed = Completer<CommandOutcome>();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.enterText(find.byType(TextField), 'saved compose');
      await tester.tap(find.text('Live edit'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'failed live buffer');
      await tester.pump(const Duration(milliseconds: 250));
      api.delayed!.complete(
        CommandOutcome(delivery: Delivery.rejected, errorCode: 'no_editor'),
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'saved compose',
      );
      await tester.pumpWidget(const SizedBox());
      expect(m.draft(('a', 'test.app')).text, 'saved compose');
      m.dispose();
    },
  );
  testWidgets('switching a composing IME into Live edit preserves Compose', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.editor!.text = 'TV field';
    m.state!.editor!.end = 8;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'かな',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Live edit'));
    await tester.pump();
    await tester.tap(find.text('Compose'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'かな',
    );
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('old live failure cannot exit a newly selected editor mode', (
    tester,
  ) async {
    final api = RecordingApi()..delayed = Completer<CommandOutcome>();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.tap(find.text('Live edit'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'old edit');
    await tester.pump(const Duration(milliseconds: 250));
    m.snapshotChanged(
      snapshot('a', 1, revision: 2)..editor!.text = 'new editor',
    );
    await tester.pump();
    await tester.tap(find.text('Live edit'));
    await tester.pump();
    api.delayed!.complete(
      CommandOutcome(delivery: Delivery.rejected, errorCode: 'no_editor'),
    );
    await tester.pump();
    final liveChip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text('Live edit'),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(liveChip.selected, isTrue);
    expect(m.messageId, 0);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'new editor',
    );
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('voice semantics distinguish preparing from recording', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final m = model(RecordingApi());
    m.state!.voiceState = 'starting';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: VoiceButton(m))));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Voice')).value,
      t('voiceStarting'),
    );
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
    m.dispose();
  });
  testWidgets('catalog only requests icons for mounted rows', (tester) async {
    final api = RecordingApi();
    final m = model(api);
    m.snapshotChanged(
      snapshot('a', 1)
        ..apps = List.generate(
          1000,
          (n) => TvApplication(id: 'app$n', name: 'App $n', uri: 'fixture:$n'),
        ),
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CatalogPage(m, apps: true))),
    );
    await tester.pump();
    expect(api.iconRequests, isNotEmpty);
    expect(api.iconRequests.length, lessThan(30));
    expect(api.iconRequests, isNot(contains('app999')));
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('live edit commits an IME composition without a text change', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.tap(find.text('Live edit'));
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'かな',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.commands, isEmpty);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'かな',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.commands.single.value, 'かな');
    expect(api.commands.single.replaceText, isTrue);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  test('native permission observation clears a stale denial banner', () {
    final m = model(RecordingApi())..networkPermissionDenied = true;
    m.snapshotChanged(snapshot('a', 2)..networkPermissionGranted = true);
    expect(m.networkPermissionDenied, isFalse);
    m.snapshotChanged(snapshot('a', 1)..networkPermissionGranted = false);
    expect(m.networkPermissionDenied, isFalse);
    m.dispose();
  });
  test('late command result cannot report an error on another TV', () async {
    final api = RecordingApi()..delayed = Completer<CommandOutcome>();
    final m = model(api);
    final command = m.command(CommandKind.key, code: 3);
    m.selected = profile('b');
    m.snapshotChanged(snapshot('b', 2));
    api.delayed!.complete(
      CommandOutcome(
        delivery: Delivery.rejected,
        errorCode: 'authentication_required',
      ),
    );
    await command;
    expect(m.messageId, 0);
    m.dispose();
  });
  testWidgets('privacy change establishes a new native input client', (
    tester,
  ) async {
    final m = model(RecordingApi());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pump();
    final before = tester.testTextInput.log
        .where((call) => call.method == 'TextInput.setClient')
        .length;
    await tester.tap(find.text('Private text'));
    await tester.pump();
    await tester.pump();
    final clients = tester.testTextInput.log
        .where((call) => call.method == 'TextInput.setClient')
        .toList();
    expect(clients.length, greaterThan(before));
    final configuration = (clients.last.arguments as List)[1] as Map;
    expect(configuration['obscureText'], isTrue);
    expect(configuration['enableIMEPersonalizedLearning'], isFalse);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  test('metadata edits never recreate a forgotten profile', () async {
    final api = SavedApi();
    final m = model(api);
    api.saved['a'] = m.selected!;
    await m.forget(m.selected!);
    await m.updateSaved(
      'a',
      (profile) => profile.updated(favorites: ['missing']),
    );
    expect(api.saved, isEmpty);
    expect(api.saves, 0);
    m.dispose();
  });
  testWidgets(
    'forgetting an open TV clears its ordinary draft after editor teardown',
    (tester) async {
      final api = SavedApi();
      final m = model(api);
      api.saved['a'] = m.selected!;
      m.profiles = List.unmodifiable([m.selected!]);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.enterText(find.byType(TextField), 'Local draft');
      await m.forget(m.selected!);
      await tester.pump();
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets('held Voice stops on pointer cancellation after acceptance', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: VoiceButton(m))));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(VoiceButton)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(api.voiceStarts, 1);
    await gesture.cancel();
    await tester.pump();
    expect(api.voiceStops, 1);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('Voice retains pointer-down session across reconnection', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    Widget view() => MaterialApp(home: Scaffold(body: VoiceButton(m)));
    await tester.pumpWidget(view());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(VoiceButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    m.snapshotChanged(snapshot('a', 2));
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 800));
    expect(api.voiceTargets, [('a', 1)]);
    await gesture.up();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('key hold retains pointer-down session across reconnection', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    Widget view() => MaterialApp(
      home: Scaffold(
        body: RemoteButton(model: m, code: 3, label: 'Home', icon: Icons.home),
      ),
    );
    await tester.pumpWidget(view());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RemoteButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    m.snapshotChanged(snapshot('a', 2));
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pump();
    expect(api.commands.map((c) => c.sessionId).toSet(), {1});
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('touchpad releases accepted hold on pointer cancellation', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.buttons.add(
      TvButton(id: 'ok', name: 'OK', androidCode: 23, canHold: true),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Touchpad(m))));
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.descendant(
          of: find.byType(Touchpad),
          matching: find.byType(GestureDetector),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.cancel();
    await tester.pump();
    expect(api.commands.map((c) => c.kind), [
      CommandKind.keyDown,
      CommandKind.keyUp,
    ]);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('private text requests an obscured non-learning IME', (
    tester,
  ) async {
    final m = model(RecordingApi());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.tap(find.text('Private text'));
    await tester.pump();
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.obscureText, isTrue);
    expect(editor.keyboardType, TextInputType.text);
    expect(editor.enableIMEPersonalizedLearning, isFalse);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('ordinary unsent compose draft survives leaving Keyboard', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.enterText(find.byType(TextField), 'Unsent local draft');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Unsent local draft',
    );
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('unsupported long press is never downgraded to a tap', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.buttons.single.canHold = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteButton(
            model: m,
            code: 3,
            label: 'Home',
            icon: Icons.home,
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RemoteButton)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pump();
    expect(api.commands, isEmpty);
    expect(m.message, contains('Press and hold'));
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('scrolling across Voice never requests microphone capture', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [VoiceButton(m), const SizedBox(height: 1500)],
          ),
        ),
      ),
    );
    await tester.drag(find.byType(VoiceButton), const Offset(0, -100));
    await tester.pump();
    expect(api.voiceStarts, 0);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('empty shortcut cannot be saved', (tester) async {
    final m = model(RecordingApi());
    await tester.pumpWidget(MaterialApp(home: ShortcutEditor(m)));
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    expect(button.onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('direct touch pinch never becomes an accidental TV tap', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.screen.value = ScreenInfo(
      textureId: 1,
      width: 640,
      height: 360,
      generation: 1,
      connected: true,
      stale: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScreenViewer(model: m, direct: true)),
      ),
    );
    await tester.pump();
    final first = await tester.startGesture(const Offset(250, 200), pointer: 1);
    await tester.pump();
    final second = await tester.startGesture(
      const Offset(350, 200),
      pointer: 2,
    );
    await tester.pump();
    await first.moveTo(const Offset(200, 200));
    await second.moveTo(const Offset(400, 200));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();
    expect(api.pointers, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('direct touch tap emits a balanced press only on release', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.screen.value = ScreenInfo(
      textureId: 1,
      width: 640,
      height: 360,
      generation: 1,
      connected: true,
      stale: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScreenViewer(model: m, direct: true)),
      ),
    );
    await tester.pump();
    final tap = await tester.startGesture(const Offset(300, 220));
    await tester.pump();
    expect(api.pointers, isEmpty);
    await tap.up();
    await tester.pump();
    expect(api.pointers.map((p) => p.$3), [1, 0]);
    expect(
      api.pointers.every(
        (p) => p.$4 == 1 && p.$1 >= 0 && p.$1 < 640 && p.$2 >= 0 && p.$2 < 360,
      ),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  test('pointer coordinates invert zoom and letterbox transforms', () {
    final transform = TransformationController(
      Matrix4.identity()
        ..translateByDouble(20, 70, 0, 1)
        ..scaleByDouble(.5, .5, 1, 1),
    );
    expect(
      framebufferPoint(const Offset(180, 115), transform, 640, 360),
      const Offset(320, 90),
    );
    expect(framebufferPoint(const Offset(19, 90), transform, 640, 360), isNull);
    expect(
      framebufferPoint(const Offset(340, 70), transform, 640, 360),
      isNull,
    );
    transform.dispose();
  });
  test('late target and session callbacks cannot replace current state', () {
    final m = model(RecordingApi());
    m.snapshotChanged(snapshot('a', 2));
    m.snapshotChanged(snapshot('a', 1));
    expect(m.state!.sessionId, 2);
    m.selected = profile('b');
    m.snapshotChanged(snapshot('b', 3));
    m.snapshotChanged(snapshot('a', 20));
    m.screenChanged('a', 20, ScreenInfo(width: 100));
    expect(m.state!.deviceId, 'b');
    expect(m.screen.value.width, 0);
    m.dispose();
  });
  testWidgets('physical press uses down and up without a duplicate tap', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteButton(
            model: m,
            code: 3,
            label: 'Home',
            icon: Icons.home,
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RemoteButton)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pump();
    expect(api.commands.map((c) => c.kind), [
      CommandKind.keyDown,
      CommandKind.keyUp,
    ]);
    expect(api.commands.map((c) => c.pressId).toSet(), hasLength(1));
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('a short tap uses the protocol SHORT direction', (tester) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteButton(
            model: m,
            code: 3,
            label: 'Home',
            icon: Icons.home,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(RemoteButton));
    await tester.pump();
    expect(api.commands.map((c) => c.kind), [CommandKind.key]);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('disposing a held button releases on the old target', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteButton(
            model: m,
            code: 3,
            label: 'Home',
            icon: Icons.home,
          ),
        ),
      ),
    );
    await tester.startGesture(tester.getCenter(find.byType(RemoteButton)));
    await tester.pump(const Duration(milliseconds: 800));
    m.selected = profile('b');
    m.snapshotChanged(snapshot('b', 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(api.commands.last.kind, CommandKind.keyUp);
    expect(api.commands.last.deviceId, 'a');
    m.dispose();
  });
  testWidgets('composition stays local until Send', (tester) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.enterText(find.byType(TextField).first, 'שלום 😀 phrase');
    await tester.pump(const Duration(seconds: 1));
    expect(api.commands, isEmpty);
    await tester.ensureVisible(find.text('Send'));
    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(api.commands.single.value, 'שלום 😀 phrase');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'שלום 😀 phrase',
    );
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('private composition is cleared on TV editor change', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.tap(find.text('Private text'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'fixture-secret');
    m.snapshotChanged(snapshot('a', 1, revision: 2));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('field switch cancels queued live edit', (tester) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.tap(find.text('Live edit'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'not the next field');
    m.snapshotChanged(snapshot('a', 1, revision: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets('backgrounding clears private input and cancels live edit', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.tap(find.text('Private text'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'fixture-secret');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
}
