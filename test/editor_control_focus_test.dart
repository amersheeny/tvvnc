import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';

import 'widget_safety_test.dart' show RecordingApi, model;

void main() {
  testWidgets('the editor semantic bounds exclude adjacent action buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final m = model(RecordingApi());
    try {
      m.state!.editor!.text = 'fixture';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: KeyboardPage(m))),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      expect(
        tester.getSemantics(field).rect.height,
        tester.getSize(field).height,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      m.dispose();
      handle.dispose();
    }
  });
  testWidgets('editing controls retain field focus for mouse input', (
    tester,
  ) async {
    final m = model(RecordingApi());
    m.state!.editor!.text = 'fixture';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    field.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.tap(
      find.byTooltip('Move cursor left'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
}
