import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';

import 'widget_safety_test.dart'
    show RecordingApi, model, snapshot, toggleMask, composeModel;

void background(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

void resume(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  testWidgets(
    'explicit Send can insert a protected fallback draft into the reported field',
    (tester) async {
      final api = RecordingApi();
      final m = composeModel(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Phone draft');
      m.snapshotChanged(
        snapshot('a', 1, revision: 7)..editor!.text = 'Existing TV value',
      );
      await tester.pumpAndSettle();
      expect(api.commands, isEmpty);
      expect(find.text('Load TV text'), findsOneWidget);
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(api.commands.single.value, 'Phone draft');
      expect(api.commands.single.editorRevision, 7);
      expect(api.commands.single.replaceText, isFalse);
      expect(m.draft(('a', 'test.app')).text, 'Phone draft');
      await tester.ensureVisible(find.text('Load TV text'));
      await tester.tap(find.text('Load TV text'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Existing TV value',
      );
      expect(api.commands.length, 1);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  for (final decision in ['cancel', 'changed', 'replace']) {
    testWidgets('paused replacement captures field and value: $decision', (
      tester,
    ) async {
      final api = RecordingApi();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Retained edit');
      m.snapshotChanged(
        snapshot('a', 1, revision: 2)..editor!.text = 'New field',
      );
      await tester.pumpAndSettle();
      expect(api.commands, isEmpty);
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      if (decision == 'changed') {
        m.snapshotChanged(
          snapshot('a', 1, revision: 3)..editor!.text = 'Another field',
        );
        await tester.pump();
      }
      await tester.tap(find.text(decision == 'cancel' ? 'Cancel' : 'Replace'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Retained edit',
      );
      if (decision == 'replace') {
        expect(api.commands.single.editorRevision, 2);
        expect(api.commands.single.replaceText, isTrue);
        expect(api.commands.single.value, 'Retained edit');
        await tester.enterText(find.byType(TextField), 'Next edit');
        await tester.pump(const Duration(milliseconds: 200));
        expect(api.commands.length, 2);
        expect(api.commands.last.replaceText, isTrue);
      } else {
        expect(api.commands, isEmpty);
      }
      expect(m.draft(('a', 'test.app')).text, isEmpty);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    });
  }
  testWidgets(
    'native editor loads automatically without editing-mode selectors',
    (tester) async {
      final m = model(RecordingApi());
      m.state!.editor!.text = 'Existing TV field';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Compose'), findsNothing);
      expect(find.text('Live edit'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Existing TV field',
      );
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );

  for (final pending in [false, true]) {
    testWidgets(
      'background and disconnect retain ordinary native edits; pending=$pending',
      (tester) async {
        final api = RecordingApi();
        if (pending) api.delayed = Completer<CommandOutcome>();
        final m = model(api);
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: KeyboardPage(m))),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Keep this edit');
        if (pending) {
          await tester.pump(const Duration(milliseconds: 200));
          api.delayed!.complete(
            CommandOutcome(
              delivery: Delivery.notSent,
              transport: 'remote',
              errorCode: 'ime_sync_pending',
            ),
          );
          await tester.pumpAndSettle();
        }
        final sent = api.commands.length;
        background(tester);
        await tester.pump();
        m.snapshotChanged(snapshot('a', 1)..editor = null);
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Keep this edit',
        );
        expect(api.commands.length, sent);
        m.snapshotChanged(
          snapshot('a', 2, revision: 3)..editor!.text = 'New TV state',
        );
        resume(tester);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Keep this edit',
        );
        expect(api.commands.length, sent);
        await tester.pumpWidget(const SizedBox());
        m.dispose();
      },
    );
  }

  testWidgets('a clean native field is present after returning to the app', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.editor!.text = 'Existing TV field';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    background(tester);
    await tester.pump();
    resume(tester);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Existing TV field',
    );
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });

  testWidgets('hiding text does not cancel its pending native edit', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Harmless protected fixture',
    );
    await toggleMask(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.commands.length, 1);
    expect(api.commands.single.value, 'Harmless protected fixture');
    expect(api.commands.single.privateText, isTrue);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });

  testWidgets(
    'visibility change keeps ownership of a native send already in flight',
    (tester) async {
      final api = RecordingApi()..delayed = Completer<CommandOutcome>();
      final m = model(api);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'One edit');
      await tester.pump(const Duration(milliseconds: 200));
      expect(api.commands.length, 1);
      await toggleMask(tester);
      await tester.pump();
      api.delayed!.complete(
        CommandOutcome(delivery: Delivery.sent, transport: 'remote'),
      );
      await tester.pumpAndSettle();
      api.delayed = null;
      await tester
          .state<KeyboardPageState>(find.byType(KeyboardPage))
          .flushLive();
      await tester.pumpAndSettle();
      expect(api.commands.length, 1);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
}
