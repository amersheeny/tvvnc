import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/ui/copy.dart';
import 'package:tv_vnc/ui/device_form.dart';

import 'widget_safety_test.dart' show RecordingApi, model, profile;

void main() {
  for (final saved in [false, true]) {
    testWidgets('TV server prerequisites are visible with saved TV: $saved', (
      tester,
    ) async {
      final api = RecordingApi();
      final m = model(api);
      m.profiles = saved ? [profile('Living room TV')] : [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DevicesPage(model: m, onSelected: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(Copy.text('tvSetupTitle')), findsOneWidget);
      expect(
        find.textContaining('VNC server app, such as droidVNC-NG'),
        findsOneWidget,
      );
      expect(find.textContaining('Depending on your TV'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('tv-setup-note'))).dy,
        lessThan(tester.getTopLeft(find.text('Find TVs')).dy),
      );
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    });
  }

  testWidgets('setup note scrolls without overflow at narrow large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final m = model(RecordingApi())..profiles = [];
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: DevicesPage(model: m, onSelected: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Enter address'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Enter address').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
}
