import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/remote_page.dart';
import 'package:tv_vnc/ui/viewer.dart';

import 'widget_safety_test.dart' show RecordingApi, model, snapshot, profile;
import 'navigation_test.dart' show mount, chooseTv, destination, back;

void main() {
  for (final size in [
    const Size(390, 780),
    const Size(900, 430),
    const Size(320, 170),
    const Size(900, 80),
  ]) {
    testWidgets('compact remote controls remain reachable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final m = model(RecordingApi());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemotePage(model: m, onPage: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Turn on'), findsNothing);
      expect(find.text('Turn off'), findsNothing);
      expect(find.byTooltip('Power'), findsNothing);
      final keyboard = find.byTooltip('Keyboard');
      if (size.width > 760 && size.height < 104) {
        await tester.scrollUntilVisible(
          keyboard,
          80,
          scrollable: find
              .descendant(
                of: find.byType(RemotePage),
                matching: find.byType(Scrollable),
              )
              .last,
          maxScrolls: 50,
        );
      } else {
        await tester.ensureVisible(keyboard);
      }
      await tester.pumpAndSettle();
      expect(tester.getSize(keyboard).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    });
  }

  testWidgets(
    'three-dot modes preserve selection and direct-touch confirmation',
    (tester) async {
      final (_, api) = await mount(tester);
      await chooseTv(tester, 'TV A');
      expect(find.text('Direct touch'), findsNothing);
      expect(find.text('Touchpad'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('tv-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Touchpad'));
      await tester.pumpAndSettle();
      expect(find.byType(Touchpad), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tv-menu')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckedPopupMenuItem<String>>(
              find.byWidgetPredicate(
                (w) =>
                    w is CheckedPopupMenuItem<String> && w.value == 'touchpad',
              ),
            )
            .checked,
        isTrue,
      );
      await tester.tap(find.text('Direct touch'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(Touchpad), findsOneWidget);
      expect(api.commands, isEmpty);
      await tester.tap(find.byKey(const ValueKey('tv-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Direct touch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ScreenViewer>(find.byType(ScreenViewer)).direct,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('tv-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remote'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ScreenViewer>(find.byType(ScreenViewer)).direct,
        isFalse,
      );
    },
  );

  for (final changed in [false, true]) {
    testWidgets('unverified power is absent across session changes: $changed', (
      tester,
    ) async {
      final api = RecordingApi();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemotePage(model: m, onPage: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Power'), findsNothing);
      if (changed) m.snapshotChanged(snapshot('a', 2));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Power'), findsNothing);
      expect(find.text('Turn off'), findsNothing);
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    });
  }
  testWidgets('changing TV cannot expose unverified power controls', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemotePage(model: m, onPage: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Power'), findsNothing);
    m.selected = profile('b');
    m.snapshotChanged(snapshot('b', 2));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Power'), findsNothing);
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });

  testWidgets('mode survives Keyboard exit and is contextual to Remote', (
    tester,
  ) async {
    await mount(tester);
    await chooseTv(tester, 'TV A');
    await tester.tap(find.byKey(const ValueKey('tv-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Touchpad'));
    await tester.pumpAndSettle();
    await destination(tester, 'Keyboard');
    await tester.tap(find.byKey(const ValueKey('tv-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Direct touch'), findsNothing);
    await back(tester);
    await tester.tap(find.byTooltip('Leave Keyboard'));
    await tester.pumpAndSettle();
    expect(find.byType(Touchpad), findsOneWidget);
    await destination(tester, 'Your TVs');
    await chooseTv(tester, 'TV B');
    expect(find.byType(Touchpad), findsNothing);
    expect(tester.widget<RemotePage>(find.byType(RemotePage)).mode, 'remote');
  });

  testWidgets('unavailable power is not exposed as a remote button', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.capabilities.add(
      CapabilityInfo(
        id: 'powerOn',
        transport: 'remote',
        state: Availability.unsupported,
        observedAt: 0,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemotePage(model: m, onPage: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Power'), findsNothing);
    expect(find.text('Turn off'), findsNothing);
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
}
