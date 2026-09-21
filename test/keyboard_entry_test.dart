import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';

import 'widget_safety_test.dart' show RecordingApi, model, snapshot;

void main() {
  testWidgets(
    'a refused Compose send retains the explanation of TV editing keys',
    (tester) async {
      final api = RecordingApi()..delayed = Completer<CommandOutcome>();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compose'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Compose fixture');
      await tester.tap(find.text('Send'));
      api.delayed!.complete(
        CommandOutcome(
          delivery: Delivery.notSent,
          transport: 'remote',
          errorCode: 'ime_sync_pending',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Your text is not going to the TV. Select Send to try again.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('These keys act on the TV, not the draft above.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  for (final action in ['send', 'paste']) {
    testWidgets(
      'late field cannot take over during a pending $action on a known target',
      (tester) async {
        final api = RecordingApi()..delayed = Completer<CommandOutcome>();
        final m = model(api);
        m.state!
          ..editor = null
          ..currentApp = 'test.app';
        final clipboard = Completer<Map<String, String>>();
        if (action == 'paste') {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async =>
                call.method == 'Clipboard.getData' ? clipboard.future : null,
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(SystemChannels.platform, null),
          );
        }
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: KeyboardPage(m))),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(action == 'send' ? 'Send' : 'Paste'));
        m.snapshotChanged(snapshot('a', 1)..editor!.text = 'TV value');
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        expect(
          tester
              .widget<ChoiceChip>(
                find.ancestor(
                  of: find.text('Compose'),
                  matching: find.byType(ChoiceChip),
                ),
              )
              .selected,
          isTrue,
        );
        if (action == 'send') {
          expect(api.commands.single.value, '');
          api.delayed!.complete(
            CommandOutcome(delivery: Delivery.sent, transport: 'test'),
          );
        } else {
          clipboard.complete({'text': 'Clipboard value'});
        }
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          action == 'paste' ? 'Clipboard value' : '',
        );
        await tester.pumpWidget(const SizedBox());
        m.dispose();
      },
    );
  }
  testWidgets(
    'initial app discovery retains the suspended Compose draft provenance',
    (tester) async {
      final api = RecordingApi();
      final m = model(api)..state = null;
      m.rememberDraft((
        'a',
        null,
      ), const TextEditingValue(text: 'Unassigned draft'));
      m.rememberDraft((
        'a',
        'test.app',
      ), const TextEditingValue(text: 'Other saved draft'));
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      m.snapshotChanged(snapshot('a', 1)..editor!.text = 'TV value');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'TV value',
      );
      await tester.tap(find.text('Compose'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unassigned draft',
      );
      expect(m.draft(('a', 'test.app')).text, 'Other saved draft');
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compose'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unassigned draft',
      );
      await tester.tap(find.text('Private text'));
      await tester.pump();
      expect(m.draft(('a', null)).text, isEmpty);
      expect(m.draft(('a', 'test.app')).text, 'Other saved draft');
      expect(m.composeContextFor(('a', 'test.app')), ('a', 'test.app'));
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  for (final action in ['typing', 'tap', 'send', 'paste']) {
    testWidgets('first native field respects prior $action intent', (
      tester,
    ) async {
      final api = RecordingApi();
      final m = model(api)..state = null;
      final clipboard = Completer<Map<String, String>>();
      if (action == 'paste') {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async =>
              call.method == 'Clipboard.getData' ? clipboard.future : null,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
      }
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      switch (action) {
        case 'typing':
          await tester.enterText(find.byType(TextField), 'Phone typing');
        case 'tap':
          await tester.tap(find.byType(TextField));
        case 'send':
          await tester.tap(find.text('Send'));
        case 'paste':
          await tester.tap(find.text('Paste'));
      }
      m.snapshotChanged(snapshot('a', 1)..editor!.text = 'TV value');
      await tester.pumpAndSettle();
      if (action == 'paste') {
        clipboard.complete({'text': 'Clipboard value'});
        await tester.pumpAndSettle();
      }
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        action == 'typing' ? 'Phone typing' : '',
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.ancestor(
                of: find.text('Compose'),
                matching: find.byType(ChoiceChip),
              ),
            )
            .selected,
        isTrue,
      );
      expect(api.commands, isEmpty);
      // A later deliberate Send uses the now-known target, not the null origin.
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(api.commands.single.deviceId, 'a');
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    });
  }
  testWidgets('a first fieldless session does not strand subsequent prefill', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api)..state = null;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    m.snapshotChanged(snapshot('a', 1)..editor = null);
    await tester.pumpAndSettle();
    m.snapshotChanged(snapshot('a', 1)..editor!.text = 'Later value');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Later value',
    );
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets(
    'private typing survives initial connection discovery without being cached',
    (tester) async {
      final api = RecordingApi();
      final m = model(api)..state = null;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private text'));
      await tester.enterText(
        find.byType(TextField),
        'Harmless private fixture',
      );
      m.snapshotChanged(snapshot('a', 1)..editor!.text = 'TV value');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Harmless private fixture',
      );
      expect(m.draft(('a', null)).text, isEmpty);
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'a platform caret movement disarms late adoption but initial focus does not',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!.editor = null;
      m.rememberDraft(
        m.draftContext,
        const TextEditingValue(text: 'Saved compose'),
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Saved compose',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      m.snapshotChanged(snapshot('a', 1)..editor!.text = 'TV value');
      await tester.pumpAndSettle();
      final value = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .value;
      expect(value.text, 'Saved compose');
      expect(value.selection.baseOffset, 3);
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'first session snapshot arriving after Keyboard opens prefills the TV field',
    (tester) async {
      final api = RecordingApi();
      final m = model(api)..state = null;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      m.snapshotChanged(snapshot('a', 1)..editor!.text = 'Already on TV');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Already on TV',
      );
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );

  testWidgets(
    'late prefill switches an untouched saved Compose buffer without deleting its draft',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!
        ..editor = null
        ..currentApp = 'test.app';
      m.rememberDraft(
        ('a', 'test.app'),
        const TextEditingValue(
          text: 'Saved compose',
          selection: TextSelection.collapsed(offset: 13),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      m.snapshotChanged(snapshot('a', 1)..editor!.text = 'Already on TV');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Already on TV',
      );
      expect(m.draft(('a', 'test.app')).text, 'Saved compose');
      await tester.tap(find.text('Compose'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Saved compose',
      );
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'counter synchronization refusal preserves the live draft for a deliberate retry',
    (tester) async {
      final api = RecordingApi()..delayed = Completer<CommandOutcome>();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Unsent edit');
      await tester.pump(const Duration(milliseconds: 200));
      api.delayed!.complete(
        CommandOutcome(
          delivery: Delivery.notSent,
          errorCode: 'ime_sync_pending',
          transport: 'remote',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unsent edit',
      );
      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('Live edit'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);
      const pending =
          'Your text is not going to the TV. Select Send to try again.';
      expect(find.text(pending), findsOneWidget);
      expect(m.message, isNull);
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      final sent = api.commands.length;
      await tester.pump(const Duration(seconds: 1));
      expect(
        api.commands.length,
        sent,
      ); // no automatic replay of the pending draft
      await tester.enterText(find.byType(TextField), 'Latest unsent edit');
      await tester.pump(const Duration(milliseconds: 300));
      expect(api.commands.length, sent);
      expect(find.text(pending), findsOneWidget);
      api.delayed = null;
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(api.commands.last.value, 'Latest unsent edit');
      expect(api.commands.last.editorRevision, 1);
      expect(api.commands.length, sent + 1);
      expect(find.text(pending), findsNothing);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'holding Backspace after clearing the field sends no duplicate replacements',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!.editor!
        ..text = 'abc'
        ..start = 3
        ..end = 3;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      final button = find.byTooltip('Backspace');
      await tester.ensureVisible(button);
      final hold = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      final count = api.commands.length;
      expect(count, greaterThan(0));
      await tester.pump(const Duration(seconds: 1));
      expect(api.commands.length, count);
      await hold.up();
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
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
