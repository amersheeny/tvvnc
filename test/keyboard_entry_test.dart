import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';

import 'widget_safety_test.dart' show RecordingApi, model, snapshot;

void main() {
  testWidgets('TV snapshots do not reopen a deliberately dismissed phone IME', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    final shows = tester.testTextInput.log
        .where((call) => call.method == 'TextInput.show')
        .length;
    m.snapshotChanged(snapshot('a', 1)..editor = null);
    await tester.pumpAndSettle();
    m.snapshotChanged(
      snapshot('a', 1, revision: 3)..editor!.text = 'New TV field',
    );
    await tester.pumpAndSettle();
    expect(
      tester.testTextInput.log
          .where((call) => call.method == 'TextInput.show')
          .length,
      shows,
    );
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets(
    'local editing deletes whole graphemes and repeat stops on disposal',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!.editor!
        ..text = 'A👨‍👩‍👧‍👦é'
        ..start = 14
        ..end = 14;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      final button = find.byTooltip('Backspace');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'A👨‍👩‍👧‍👦',
      );
      await tester.tap(button);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'A',
      );
      final hold = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpWidget(const SizedBox());
      await hold.up();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      m.dispose();
    },
  );

  testWidgets('TV Enter flushes text first and holds retain their key-up', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.buttons.add(
      TvButton(
        id: 'enter',
        name: 'Enter',
        androidCode: 66,
        canHold: true,
        state: Availability.ready,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'final search');
    final button = find.byTooltip('Enter on TV');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(api.commands.map((c) => c.kind), [
      CommandKind.text,
      CommandKind.key,
    ]);
    expect(api.commands.first.value, 'final search');
    expect(api.commands.last.code, 66);
    m.snapshotChanged(
      snapshot('a', 1, revision: 2)
        ..buttons.add(
          TvButton(
            id: 'enter',
            name: 'Enter',
            androidCode: 66,
            canHold: true,
            state: Availability.ready,
          ),
        ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(button);
    final hold = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 600));
    await hold.up();
    await tester.pump();
    expect(api.commands[api.commands.length - 2].kind, CommandKind.keyDown);
    expect(api.commands.last.kind, CommandKind.keyUp);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });

  testWidgets(
    'leaving drains the newest committed edit after an in-flight edit',
    (tester) async {
      final api = RecordingApi()..delayed = Completer<CommandOutcome>();
      final m = model(api);
      final key = GlobalKey<KeyboardPageState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: KeyboardPage(m, key: key)),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'first');
      await tester.pump(const Duration(milliseconds: 200));
      expect(api.commands.single.value, 'first');
      await tester.enterText(find.byType(TextField), 'first plus final');
      final leaving = key.currentState!.prepareToLeave();
      await tester.pump();
      expect(api.commands.length, 1);
      api.delayed!.complete(
        CommandOutcome(delivery: Delivery.sent, transport: 'test'),
      );
      await tester.pump();
      expect(await leaving, isTrue);
      expect(api.commands.map((c) => c.value), ['first', 'first plus final']);
      expect(
        api.commands.every(
          (c) => c.replaceText == true && c.editorRevision == 1,
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );

  testWidgets(
    'dirty field change pauses without erasing or replaying local text',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Unfinished edit');
      m.snapshotChanged(
        snapshot('a', 1, revision: 2)..editor!.text = 'Other field',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unfinished edit',
      );
      expect(api.commands, isEmpty);
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      await tester.pumpWidget(const SizedBox());
      expect(api.commands, isEmpty);
      m.dispose();
    },
  );

  testWidgets(
    'clean Live follows counter reset without manual mode selection',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pump();
      m.snapshotChanged(snapshot('a', 1)..editor = null);
      await tester.pump();
      m.snapshotChanged(
        snapshot('a', 1, revision: 3)..editor!.text = 'Current field',
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Current field',
      );
      expect(api.commands, isEmpty);
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );

  testWidgets('older own echo cannot overwrite a newer phone edit or caret', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'newer');
    m.snapshotChanged(snapshot('a', 1)..editor!.text = 'first');
    await tester.pump();
    final value = tester
        .widget<TextField>(find.byType(TextField))
        .controller!
        .value;
    expect(value.text, 'newer');
    expect(value.selection.extentOffset, 5);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });

  testWidgets('opening Keyboard imports the TV field without sending it', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.editor!
      ..text = 'Existing TV search 😀'
      ..start = 9
      ..end = 11;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Existing TV search 😀');
    expect(
      field.controller!.selection,
      const TextSelection(baseOffset: 9, extentOffset: 11),
    );
    expect(field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(field.enableIMEPersonalizedLearning, isFalse);
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    expect(api.commands, isEmpty);
    expect(m.draft(('a', 'test.app')).text, isEmpty);
    m.dispose();
  });

  testWidgets('late TV field prefills an untouched keyboard only', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.editor = null;
    m.state!.currentApp = 'test.app';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    m.snapshotChanged(snapshot('a', 1)..editor!.text = 'Late TV field');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Late TV field',
    );
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });

  testWidgets('late TV field never overwrites a phone draft', (tester) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.editor = null;
    m.state!.currentApp = 'test.app';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Phone draft');
    m.snapshotChanged(snapshot('a', 1)..editor!.text = 'Late TV field');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Phone draft',
    );
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
}
