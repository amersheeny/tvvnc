import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';

import 'widget_safety_test.dart'
    show RecordingApi, model, snapshot, composeModel;

void main() {
  for (final custom in [false, true]) {
    testWidgets(
      'next editor retains focus across action completion: custom=$custom',
      (tester) async {
        final api = RecordingApi()..delayed = Completer<CommandOutcome>();
        final m = model(api);
        m.state!.editor!
          ..inputType = 1
          ..imeOptions = 5
          ..actionLabel = custom ? 'Continue fixture' : null
          ..actionId = custom ? 91 : null;
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: KeyboardPage(m))),
        );
        await tester.pumpAndSettle();
        if (custom) {
          await tester.tap(
            find.widgetWithText(FilledButton, 'Continue fixture'),
          );
        } else {
          tester.widget<TextField>(find.byType(TextField)).onSubmitted!('');
        }
        await tester.pump();
        m.snapshotChanged(
          snapshot('a', 1, revision: 2)
            ..editor!.inputType = 0x81
            ..editor!.imeOptions = 6,
        );
        await tester.pump();
        final pending = api.delayed!;
        api.delayed = null;
        pending.complete(CommandOutcome(delivery: Delivery.sent));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
          isTrue,
        );
        expect(api.commands.single.kind, CommandKind.editorAction);
        await tester.pumpWidget(const SizedBox());
        m.dispose();
      },
    );
  }
  for (final multiline in [false, true]) {
    for (final fails in [false, true]) {
      testWidgets(
        'custom action flushes edits without relabelling Enter: multiline=$multiline failed=$fails',
        (tester) async {
          final api = RecordingApi()..delayed = Completer<CommandOutcome>();
          final m = model(api);
          m.state!.editor!
            ..inputType = multiline ? 0x20001 : 1
            ..imeOptions = multiline ? 0x40000001 : 3
            ..actionLabel = 'Confirm fixture'
            ..actionId = 91;
          await tester.pumpWidget(
            MaterialApp(home: Scaffold(body: KeyboardPage(m))),
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'fixture edit');
          await tester.pump();
          final field = tester.widget<TextField>(find.byType(TextField));
          expect(
            field.textInputAction,
            multiline ? TextInputAction.newline : TextInputAction.none,
          );
          await tester.tap(
            find.widgetWithText(FilledButton, 'Confirm fixture'),
          );
          await tester.pump();
          expect(api.commands, hasLength(1));
          final pending = api.delayed!;
          api.delayed = null;
          pending.complete(
            CommandOutcome(delivery: fails ? Delivery.notSent : Delivery.sent),
          );
          await tester.pumpAndSettle();
          expect(
            api.commands
                .where((c) => c.kind == CommandKind.editorAction)
                .length,
            fails ? 0 : 1,
          );
          if (!fails) expect(field.focusNode!.hasFocus, isTrue);
          await tester.pumpWidget(const SizedBox());
          m.dispose();
        },
      );
    }
  }
  testWidgets('revealing then clearing a TV password keeps protection', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.editor!
      ..inputType = 0x81
      ..imeOptions = 6
      ..text = 'private fixture';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show text'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'replacement fixture');
    await tester.pumpAndSettle();
    expect(api.commands.last.privateText, isTrue);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enableSuggestions, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(field.controller!.text, isEmpty);
    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    m.dispose();
  });
  testWidgets('a custom TV action does not masquerade as phone Search', (
    tester,
  ) async {
    final m = model(RecordingApi());
    m.state!.editor!
      ..inputType = 1
      ..imeOptions = 3
      ..actionLabel = 'Confirm fixture'
      ..actionId = 91;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).textInputAction,
      TextInputAction.none,
    );
    expect(find.text('Confirm fixture'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets(
    'a late declared password protects the draft without replacing it',
    (tester) async {
      final api = RecordingApi();
      final m = composeModel(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pending fixture');
      m.snapshotChanged(
        snapshot('a', 1, revision: 2)
          ..editor!.inputType = 0x81
          ..editor!.imeOptions = 6
          ..editor!.text = 'server fixture',
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.controller!.text, 'pending fixture');
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'fresh editor after a clean same-TV reconnect prefills automatically',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!.editor!.text = 'observed field';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      m.snapshotChanged(
        snapshot('a', 2, revision: 2)..editor!.text = 'fresh field',
      );
      await tester.pumpAndSettle();
      final state = tester.state<KeyboardPageState>(find.byType(KeyboardPage));
      expect(state.live, isTrue);
      expect(state.text.text, 'fresh field');
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'editing the same observed field after Search resumes live mirroring',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!.editor!
        ..inputType = 1
        ..imeOptions = 3
        ..text = 'query'
        ..start = 5
        ..end = 5;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      tester.widget<TextField>(find.byType(TextField)).onSubmitted!('query');
      await tester.pumpAndSettle();
      expect(api.commands.single.kind, CommandKind.editorAction);
      await tester.enterText(find.byType(TextField), 'query2');
      await tester.pumpAndSettle();
      expect(api.commands.last.kind, CommandKind.text);
      expect(api.commands.last.value, 'query2');
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'focus changing during the flush prevents the old Search action',
    (tester) async {
      final api = RecordingApi()..delayed = Completer<CommandOutcome>();
      final m = model(api);
      m.state!.editor!
        ..inputType = 1
        ..imeOptions = 3;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'query');
      await tester.pump();
      tester.widget<TextField>(find.byType(TextField)).onSubmitted!('query');
      await tester.pump();
      m.snapshotChanged(
        snapshot('a', 1, revision: 2)..editor!.text = 'different field',
      );
      final pending = api.delayed!;
      api.delayed = null;
      pending.complete(CommandOutcome(delivery: Delivery.sent));
      await tester.pumpAndSettle();
      expect(
        api.commands.where((c) => c.kind == CommandKind.editorAction),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  for (final inputType in [0x81, 0x91, 0xe1, 0x12, 0x20081]) {
    testWidgets('TV password metadata masks the prefilled value: $inputType', (
      tester,
    ) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!.editor = EditorInfo.decode(<Object?>[
        'test.app',
        'Password',
        'private fixture',
        15,
        15,
        1,
        inputType,
        6,
        null,
        null,
      ]);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'private fixture');
      expect(field.obscureText, isTrue);
      expect(field.maxLines, 1);
      if (inputType == 0x12) {
        expect(field.keyboardType.index, TextInputType.number.index);
      }
      expect(field.enableIMEPersonalizedLearning, isFalse);
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    });
  }
  testWidgets(
    'revealed declared-password text stays protected and clears on background',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.rememberDraft((
        'a',
        'test.app',
      ), const TextEditingValue(text: 'cached fixture'));
      m.state!.editor!.inputType = 0x81;
      m.state!.editor!.imeOptions = 6;
      m.state!.editor!.text = 'private fixture';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      await tester.tap(find.byTooltip('Show text'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
      expect(field.enableIMEPersonalizedLearning, isFalse);
      expect(field.enableSuggestions, isFalse);
      await tester.enterText(find.byType(TextField), 'new private fixture');
      await tester.pumpAndSettle();
      expect(api.commands.last.privateText, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(field.controller!.text, isEmpty);
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      m.dispose();
    },
  );
  testWidgets(
    'leaving a declared password restores the earlier mask preference',
    (tester) async {
      final m = model(RecordingApi());
      m.state!.editor!.inputType = 0x81;
      m.state!.editor!.text = 'private fixture';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      m.snapshotChanged(
        snapshot('a', 1, revision: 2)
          ..editor!.inputType = 1
          ..editor!.imeOptions = 3
          ..editor!.text = 'ordinary field',
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
      expect(field.controller!.text, 'ordinary field');
      expect(field.textInputAction, TextInputAction.search);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  for (final fails in [false, true]) {
    testWidgets(
      'Search waits for a successful edit before submitting: $fails',
      (tester) async {
        final api = RecordingApi()..delayed = Completer<CommandOutcome>();
        final m = model(api);
        m.state!.editor!
          ..inputType = 1
          ..imeOptions = 3;
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: KeyboardPage(m))),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'search fixture');
        await tester.pump();
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.textInputAction, TextInputAction.search);
        field.onSubmitted!('search fixture');
        await tester.pump();
        expect(api.commands, hasLength(1));
        final pending = api.delayed!;
        api.delayed = null;
        pending.complete(
          CommandOutcome(
            delivery: fails ? Delivery.notSent : Delivery.sent,
            errorCode: fails ? 'editor_changed' : null,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          api.commands.where((c) => c.kind == CommandKind.editorAction),
          hasLength(fails ? 0 : 1),
        );
        if (!fails) expect(api.commands.last.editorRevision, 1);
        await tester.pumpWidget(const SizedBox());
        m.dispose();
      },
    );
  }
  testWidgets(
    'a true multiline editor keeps newline instead of a submit action',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!.editor!
        ..inputType = 0x20001
        ..imeOptions = 0x40000006;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textInputAction, TextInputAction.newline);
      expect(field.maxLines, 3);
      await tester.enterText(find.byType(TextField), 'one\ntwo');
      await tester.pumpAndSettle();
      field.onSubmitted!('one\ntwo');
      await tester.pumpAndSettle();
      expect(api.commands.single.value, 'one\ntwo');
      expect(
        api.commands.where((c) => c.kind == CommandKind.editorAction),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
}
