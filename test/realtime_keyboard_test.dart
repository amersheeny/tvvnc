import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';

import 'widget_safety_test.dart' show RecordingApi, model, snapshot;

void main() {
  testWidgets(
    'a sent but unobserved edit survives an unexpected field change',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Keep until observed');
      await tester.pumpAndSettle();
      expect(api.commands.single.value, 'Keep until observed');
      m.snapshotChanged(
        snapshot('a', 1, revision: 2)..editor!.text = 'Different field',
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Keep until observed',
      );
      expect(api.commands.length, 1);
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'continuous composing typing mirrors without waiting for a pause',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      for (final value in ['a', 'ab', 'abc']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
            composing: TextRange(start: 0, end: value.length),
          ),
        );
        await tester.idle();
        expect(api.commands.last.value, value);
      }
      expect(api.commands.length, 3);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'in-flight typing sends the latest buffer in order without overlap',
    (tester) async {
      final api = RecordingApi()..delayed = Completer<CommandOutcome>();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      expect(api.commands.single.value, 'a');
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(api.commands.length, 1);
      final completion = api.delayed!;
      api.delayed = null;
      completion.complete(CommandOutcome(delivery: Delivery.sent));
      await tester.pumpAndSettle();
      expect(api.commands.map((c) => c.value), ['a', 'abc']);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
}
