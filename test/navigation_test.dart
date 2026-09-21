import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/model/tv_model.dart';
import 'package:tv_vnc/ui/catalog_pages.dart';
import 'package:tv_vnc/ui/console.dart';
import 'package:tv_vnc/ui/device_form.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';
import 'package:tv_vnc/ui/remote_page.dart';
import 'package:tv_vnc/ui/shortcuts_page.dart';
import 'package:tv_vnc/ui/viewer.dart';

import 'widget_safety_test.dart' show SavedApi, profile, snapshot;

class NavigationApi extends SavedApi {
  final connections = <String>[];
  final disconnections = <String>[];
  @override
  Future<bool> requestNetworkPermission() async => true;
  @override
  Future<SessionSnapshot> connect(String id) async {
    connections.add(id);
    return snapshot(id, connections.length)
      ..buttons.add(
        TvButton(
          id: 'back',
          name: 'Back',
          androidCode: 4,
          canHold: true,
          state: Availability.ready,
        ),
      );
  }

  @override
  Future<void> disconnect(String id, int session) async {
    disconnections.add(id);
  }
}

Future<(TvModel, NavigationApi)> mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = NavigationApi();
  for (final id in ['TV A', 'TV B']) {
    api.saved[id] = profile(id);
  }
  final model = TvModel(api: api)..profiles = api.saved.values.toList();
  await tester.pumpWidget(
    MaterialApp(
      home: Console(model: model, theme: ThemeMode.system, onTheme: (_) {}),
    ),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
  return (model, api);
}

Future<void> chooseTv(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  expect(find.byType(RemotePage), findsOneWidget);
}

Future<void> destination(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  final item = find.descendant(
    of: find.byType(NavigationDrawer),
    matching: find.text(label),
  );
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

bool canPop(WidgetTester tester) =>
    Navigator.of(tester.element(find.byType(Console))).canPop();

void main() {
  testWidgets('drawer Back does not leave Keyboard while an edit is in flight', (
    tester,
  ) async {
    final (_, api) = await mount(tester);
    await chooseTv(tester, 'TV A');
    await destination(tester, 'Keyboard');
    api.delayed = Completer<CommandOutcome>();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'かな',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    // Opening the drawer blurs the input and legitimately commits composition.
    // Back must close only the drawer, without invoking the page-exit drain.
    expect(api.commands.length, 1);
    await back(tester);
    expect(find.byType(KeyboardPage), findsOneWidget);
    expect(
      tester.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen,
      isFalse,
    );
    expect(api.commands.length, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    api.delayed!.complete(CommandOutcome(delivery: Delivery.sent));
    await tester.pump();
  });
  testWidgets('visible Leave Keyboard returns to prior page without TV Back', (
    tester,
  ) async {
    final (_, api) = await mount(tester);
    await chooseTv(tester, 'TV A');
    await destination(tester, 'Apps');
    await destination(tester, 'Keyboard');
    await tester.tap(find.byTooltip('Leave Keyboard'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogPage), findsOneWidget);
    expect(api.commands, isEmpty);
  });
  testWidgets('fullscreen Back returns to the remote before the device list', (
    tester,
  ) async {
    await mount(tester);
    await chooseTv(tester, 'TV A');
    await tester.ensureVisible(find.byTooltip('Full screen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Full screen'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ScreenViewer>(find.byType(ScreenViewer)).fullscreen,
      isTrue,
    );
    await back(tester);
    expect(find.byType(RemotePage), findsOneWidget);
    await back(tester);
    expect(find.byType(DevicesPage), findsOneWidget);
  });

  testWidgets(
    'returning through history never restores private keyboard text',
    (tester) async {
      final (model, _) = await mount(tester);
      await chooseTv(tester, 'TV A');
      await destination(tester, 'Keyboard');
      await tester.tap(find.text('Private text'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'private navigation fixture',
      );
      await destination(tester, 'Apps');
      await back(tester);
      expect(find.byType(KeyboardPage), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(model.draft(('TV A', 'test.app')).text, isEmpty);
    },
  );

  testWidgets('leaving remote releases a held key on its captured TV', (
    tester,
  ) async {
    final (_, api) = await mount(tester);
    await chooseTv(tester, 'TV A');
    await tester.ensureVisible(find.text('Home'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Home')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(api.commands.single.kind, CommandKind.keyDown);
    await back(tester);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(DevicesPage), findsOneWidget);
    expect(api.commands.map((command) => command.kind), [
      CommandKind.keyDown,
      CommandKind.keyUp,
    ]);
    expect(api.commands.last.deviceId, api.commands.first.deviceId);
    expect(api.commands.last.sessionId, api.commands.first.sessionId);
    expect(api.commands.last.pressId, api.commands.first.pressId);
  });

  testWidgets('system Back retraces pages without TV commands or reconnects', (
    tester,
  ) async {
    final (_, api) = await mount(tester);
    expect(canPop(tester), isFalse);
    await chooseTv(tester, 'TV A');
    await destination(tester, 'Keyboard');
    expect(find.byType(KeyboardPage), findsOneWidget);
    await back(tester);
    expect(find.byType(RemotePage), findsOneWidget);
    await back(tester);
    expect(find.byType(DevicesPage), findsOneWidget);
    expect(canPop(tester), isFalse);
    expect(api.connections, ['TV A']);
    expect(api.disconnections, isEmpty);
    expect(api.commands, isEmpty);
  });

  testWidgets(
    'history follows actual page order and ignores duplicate selection',
    (tester) async {
      await mount(tester);
      await chooseTv(tester, 'TV A');
      await destination(tester, 'Keyboard');
      await destination(tester, 'Apps');
      await destination(tester, 'Inputs');
      await destination(tester, 'Inputs');
      await back(tester);
      expect(tester.widget<CatalogPage>(find.byType(CatalogPage)).apps, isTrue);
      await back(tester);
      expect(find.byType(KeyboardPage), findsOneWidget);
      await back(tester);
      expect(find.byType(RemotePage), findsOneWidget);
    },
  );

  testWidgets('drawer and form dismissal do not consume page history', (
    tester,
  ) async {
    final (model, _) = await mount(tester);
    await chooseTv(tester, 'TV A');
    await destination(tester, 'Keyboard');
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await back(tester);
    expect(find.byType(KeyboardPage), findsOneWidget);
    expect(
      tester.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen,
      isFalse,
    );
    final dialog = editDevice(
      tester.element(find.byType(Console)),
      model,
      profile: model.selected,
    );
    await tester.pumpAndSettle();
    expect(find.byType(DeviceForm), findsOneWidget);
    await back(tester);
    expect(await dialog, isNull);
    expect(find.byType(KeyboardPage), findsOneWidget);
    await back(tester);
    expect(find.byType(RemotePage), findsOneWidget);
  });

  testWidgets(
    'pushed customization and shortcut editor return to their owning page',
    (tester) async {
      await mount(tester);
      await chooseTv(tester, 'TV A');
      await destination(tester, 'Settings');
      await tester.tap(find.text('Customize remote'));
      await tester.pumpAndSettle();
      expect(find.byType(CustomizePage), findsOneWidget);
      await back(tester);
      expect(find.byType(SettingsPage), findsOneWidget);
      await destination(tester, 'Shortcuts');
      await tester.tap(find.text('Add shortcut'));
      await tester.pumpAndSettle();
      expect(find.byType(ShortcutEditor), findsOneWidget);
      await back(tester);
      expect(find.byType(ShortcutsPage), findsOneWidget);
      await back(tester);
      expect(find.byType(SettingsPage), findsOneWidget);
      await back(tester);
      expect(find.byType(RemotePage), findsOneWidget);
    },
  );

  testWidgets('going to Your TVs and changing TV clears former history', (
    tester,
  ) async {
    final (model, api) = await mount(tester);
    await chooseTv(tester, 'TV A');
    await destination(tester, 'Keyboard');
    await destination(tester, 'Your TVs');
    expect(find.byType(DevicesPage), findsOneWidget);
    expect(canPop(tester), isFalse);
    await chooseTv(tester, 'TV B');
    await back(tester);
    expect(find.byType(DevicesPage), findsOneWidget);
    expect(canPop(tester), isFalse);
    expect(model.selected!.id, 'TV B');
    expect(api.connections, ['TV A', 'TV B']);
    expect(api.disconnections, ['TV A']);
  });

  testWidgets(
    'forgetting selected TV clears page history and stale destinations',
    (tester) async {
      final (model, _) = await mount(tester);
      await chooseTv(tester, 'TV A');
      await destination(tester, 'Keyboard');
      await model.forget(model.selected!);
      await tester.pumpAndSettle();
      expect(find.byType(DevicesPage), findsOneWidget);
      expect(canPop(tester), isFalse);
      await chooseTv(tester, 'TV B');
      await back(tester);
      expect(find.byType(DevicesPage), findsOneWidget);
      expect(canPop(tester), isFalse);
    },
  );

  testWidgets('on-screen remote Back remains an Android TV key', (
    tester,
  ) async {
    final (_, api) = await mount(tester);
    await chooseTv(tester, 'TV A');
    await tester.ensureVisible(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(api.commands.single.code, 4);
    expect(find.byType(RemotePage), findsOneWidget);
    await back(tester);
    expect(find.byType(DevicesPage), findsOneWidget);
    expect(api.commands, hasLength(1));
  });
}
