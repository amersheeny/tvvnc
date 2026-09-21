import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';
import 'package:tv_vnc/ui/resizable_screen.dart';

import 'widget_safety_test.dart' show RecordingApi, model;

void main() {
  testWidgets(
    'short panes keep the entire resize band visible and retain every viewing action',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.screen.value = ScreenInfo(
        textureId: 1,
        width: 1280,
        height: 720,
        generation: 1,
        connected: true,
        stale: false,
      );
      final height = ValueNotifier<double>(78);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<double>(
              valueListenable: height,
              builder: (_, maximum, _) => Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 450,
                  child: ResizableScreen(
                    model: m,
                    height: m.remoteScreenHeight,
                    defaultViewerHeight: 220,
                    maximumHeight: maximum,
                    availableHeight: 600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pane = tester.getRect(
        find.byKey(const ValueKey('resizable-screen')),
      );
      final handle = tester.getRect(
        find.byKey(const ValueKey('screen-resize-handle')),
      );
      expect(handle.top, greaterThanOrEqualTo(pane.top));
      expect(handle.bottom, lessThanOrEqualTo(pane.bottom));
      expect(handle.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byTooltip('Screen options'));
      await tester.pumpAndSettle();
      for (final label in [
        'Fit',
        'Actual size',
        'Zoom in',
        'Zoom out',
        'Save screenshot',
        'Reconnect',
        'Hide screen',
        'Full screen',
      ]) {
        expect(
          find.widgetWithText(PopupMenuItem<IconButton>, label),
          findsOneWidget,
        );
      }
      // Opening a menu can hide the phone IME and grow the available height.
      // Keep the launching menu mounted so its selection is not discarded.
      height.value = 400;
      await tester.pumpAndSettle();
      final controller = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final before = controller.value.entry(0, 0);
      await tester.tap(find.text('Zoom in'));
      await tester.pumpAndSettle();
      expect(controller.value.entry(0, 0), closeTo(before * 1.4, .00001));
      expect(api.commands, isEmpty);
      await tester.pumpWidget(const SizedBox());
      height.dispose();
      m.dispose();
    },
  );
  testWidgets('rotation preserves the active editor client and composition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'かな',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump();
    final clientCount = tester.testTextInput.log
        .where((call) => call.method == 'TextInput.setClient')
        .length;
    tester.view.physicalSize = const Size(2400, 1080);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.controller!.value.composing,
      const TextRange(start: 0, end: 2),
    );
    expect(field.controller!.text, 'かな');
    expect(field.focusNode!.hasFocus, isTrue);
    expect(
      tester.testTextInput.log
          .where((call) => call.method == 'TextInput.setClient')
          .length,
      clientCount,
    );
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });

  testWidgets(
    'handle pointer-down releases an existing TV drag even at the height limit',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.remoteScreenHeight.value = 300;
      m.screen.value = ScreenInfo(
        textureId: 1,
        width: 1280,
        height: 720,
        generation: 1,
        connected: true,
        stale: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: ResizableScreen(
                model: m,
                height: m.remoteScreenHeight,
                defaultViewerHeight: 250,
                maximumHeight: 300,
                availableHeight: 600,
                direct: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = await tester.startGesture(
        const Offset(400, 100),
        pointer: 1,
      );
      await first.moveBy(const Offset(35, 0));
      await tester.pump();
      expect(api.pointers.last.$3, 1);
      final second = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('screen-resize-handle'))),
        pointer: 2,
      );
      await tester.pump();
      expect(api.pointers.last.$3, 0);
      expect(m.remoteScreenHeight.value, 300);
      await second.up();
      await first.up();
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  testWidgets(
    'drag and accessible resize stay local and preserve preferred height through clamps',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      final semantics = tester.ensureSemantics();
      final height = ValueNotifier<double>(600);
      Widget app() => MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<double>(
            valueListenable: height,
            builder: (context, maximum, _) => Align(
              alignment: Alignment.topCenter,
              child: ResizableScreen(
                model: m,
                height: m.remoteScreenHeight,
                defaultViewerHeight: 220,
                maximumHeight: maximum,
                availableHeight: 600,
                direct: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final pane = find.byKey(const ValueKey('resizable-screen'));
      final handle = find.byKey(const ValueKey('screen-resize-handle'));
      final before = tester.getSize(pane).height;
      await tester.drag(handle, const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(tester.getSize(pane).height, greaterThan(before));
      final chosen = m.remoteScreenHeight.value!;
      height.value = 150;
      await tester.pumpAndSettle();
      expect(tester.getSize(pane).height, 150);
      expect(m.remoteScreenHeight.value, chosen);
      height.value = 600;
      await tester.pumpAndSettle();
      expect(tester.getSize(pane).height, chosen);
      final node = tester.getSemantics(handle);
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          nodeId: node.id,
          viewId: tester.view.viewId,
          type: SemanticsAction.increase,
        ),
      );
      await tester.pumpAndSettle();
      expect(m.remoteScreenHeight.value, chosen + 16);
      m.screen.value = ScreenInfo(hidden: true);
      await tester.pumpAndSettle();
      expect(handle, findsNothing);
      expect(tester.getSize(pane).height, 48);
      m.screen.value = ScreenInfo(hidden: false);
      await tester.pumpAndSettle();
      expect(tester.getSize(pane).height, chosen + 16);
      expect(api.commands, isEmpty);
      expect(api.pointers, isEmpty);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
      height.dispose();
      m.dispose();
    },
  );

  testWidgets('resizing Keyboard leaves phone input focused and visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = RecordingApi();
    final m = model(api);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: KeyboardPage(m))));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.drag(
      find.byKey(const ValueKey('screen-resize-handle')),
      const Offset(0, -60),
    );
    await tester.pumpAndSettle();
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(api.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });

  testWidgets('manual zoom and Actual size survive pane resizing', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.screen.value = ScreenInfo(
      textureId: 1,
      width: 1920,
      height: 1080,
      generation: 1,
      connected: true,
      stale: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ResizableScreen(
              model: m,
              height: m.remoteScreenHeight,
              defaultViewerHeight: 250,
              maximumHeight: 500,
              availableHeight: 600,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final fitted = controller.value.entry(0, 0);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    final zoom = controller.value.entry(0, 0);
    expect(zoom, closeTo(fitted * 1.4, .00001));
    await tester.drag(
      find.byKey(const ValueKey('screen-resize-handle')),
      const Offset(0, 60),
    );
    await tester.pumpAndSettle();
    expect(controller.value.entry(0, 0), closeTo(zoom, .00001));
    await tester.tap(find.byTooltip('Actual size'));
    await tester.pump();
    final actual = controller.value.entry(0, 0);
    expect(actual, closeTo(1 / tester.view.devicePixelRatio, .00001));
    await tester.drag(
      find.byKey(const ValueKey('screen-resize-handle')),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();
    expect(controller.value.entry(0, 0), closeTo(actual, .00001));
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
}
