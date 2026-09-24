import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';

import 'widget_safety_test.dart' show RecordingApi, model, snapshot;

void main() {
  for (final throughButton in [false, true]) {
    testWidgets('live cursor movement reaches the TV: $throughButton', (
      tester,
    ) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!.editor!
        ..text = 'abcd'
        ..start = 4
        ..end = 4;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      expect(api.commands, isEmpty);
      final state = tester.state<KeyboardPageState>(find.byType(KeyboardPage));
      if (throughButton) {
        state.editLocally(21);
      } else {
        state.text.selection = const TextSelection(
          baseOffset: 1,
          extentOffset: 3,
        );
      }
      await tester.pumpAndSettle();
      expect(api.commands, hasLength(1));
      expect(api.commands.single.kind, CommandKind.text);
      expect(api.commands.single.value, 'abcd');
      expect(api.commands.single.replaceText, isTrue);
      expect(api.commands.single.selectionStart, throughButton ? 3 : 1);
      expect(api.commands.single.selectionEnd, 3);
      m.snapshotChanged(
        snapshot('a', 1)
          ..editor!.text = 'abcd'
          ..editor!.start = throughButton ? 3 : 1
          ..editor!.end = 3,
      );
      await tester.pumpAndSettle();
      expect(api.commands, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    });
  }
  testWidgets('pristine TV caret updates never send a command back', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.editor!
      ..text = 'abcd'
      ..start = 4
      ..end = 4;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    m.snapshotChanged(
      snapshot('a', 1)
        ..editor!.text = 'abcd'
        ..editor!.start = 1
        ..editor!.end = 3,
    );
    await tester.pumpAndSettle();
    expect(api.commands, isEmpty);
    final state = tester.state<KeyboardPageState>(find.byType(KeyboardPage));
    expect(
      state.text.selection,
      const TextSelection(baseOffset: 1, extentOffset: 3),
    );
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets(
    'a caret move queued behind typing sends the latest selection once',
    (tester) async {
      final api = RecordingApi()..delayed = Completer<CommandOutcome>();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'abcdef');
      await tester.pump();
      final state = tester.state<KeyboardPageState>(find.byType(KeyboardPage));
      state.text.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();
      state.text.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();
      expect(api.commands, hasLength(1));
      final completion = api.delayed!;
      api.delayed = null;
      completion.complete(CommandOutcome(delivery: Delivery.sent));
      await tester.pumpAndSettle();
      expect(api.commands, hasLength(2));
      expect(api.commands.last.value, 'abcdef');
      expect(api.commands.last.selectionStart, 2);
      expect(api.commands.last.selectionEnd, 2);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets('a queued caret move never follows focus into another field', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.editor!
      ..text = 'abcd'
      ..start = 4
      ..end = 4;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    final state = tester.state<KeyboardPageState>(find.byType(KeyboardPage));
    state.text.selection = const TextSelection.collapsed(offset: 2);
    m.snapshotChanged(snapshot('a', 1, revision: 2)..editor!.text = 'another');
    await tester.pumpAndSettle();
    expect(api.commands, isEmpty);
    expect(state.pausedEdit, isTrue);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
}
