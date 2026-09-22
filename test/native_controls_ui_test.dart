import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/bridge/tv_api.g.dart';
import 'package:tv_vnc/ui/remote_page.dart';

import 'widget_safety_test.dart' show RecordingApi, model;

void main() {
  testWidgets('identified TV exposes only a compact genuine power toggle', (
    tester,
  ) async {
    final api = RecordingApi();
    final m = model(api);
    m.state!.capabilities.add(
      CapabilityInfo(
        id: 'powerToggle',
        state: Availability.ready,
        transport: 'composite',
        observedAt: 1,
        detail: 'tv',
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
    expect(find.text('Turn on'), findsNothing);
    expect(find.text('Turn off'), findsNothing);
    final power = find.byTooltip('Power');
    expect(power, findsOneWidget);
    expect(tester.getSize(power).height, greaterThanOrEqualTo(48));
    await tester.tap(power);
    await tester.pumpAndSettle();
    expect(api.commands.single.kind, CommandKind.powerToggle);
    await tester.pumpWidget(const SizedBox());
    m.dispose();
  });
  testWidgets(
    'native volume range and output ownership reach the semantic command',
    (tester) async {
      final api = RecordingApi();
      final m = model(api);
      m.state!
        ..volume = 20
        ..volumeMin = 10
        ..volumeMax = 30
        ..volumeContext = 'output-a';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: VolumeSlider(m))),
      );
      await tester.pumpAndSettle();
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 10);
      expect(slider.max, 30);
      expect(slider.value, 20);
      slider.onChangeStart!(20);
      m.state!.volumeContext = 'output-b';
      slider.onChangeEnd!(25);
      await tester.pumpAndSettle();
      expect(api.commands.single.kind, CommandKind.volume);
      expect(api.commands.single.value, 'output-a');
      expect(api.commands.single.number, 25);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
  for (final missing in ['minimum', 'maximum', 'level', 'context']) {
    testWidgets('absolute slider never invents missing $missing', (
      tester,
    ) async {
      final m = model(RecordingApi());
      m.state!
        ..volume = missing == 'level' ? null : 15
        ..volumeMin = missing == 'minimum' ? null : 10
        ..volumeMax = missing == 'maximum' ? null : 30
        ..volumeContext = missing == 'context' ? null : 'sony:headphone:10:30';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: VolumeSlider(m))),
      );
      expect(find.byType(Slider), findsNothing);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    });
  }
  testWidgets(
    'Sony slider identifies its named output in visual and spoken text',
    (tester) async {
      final m = model(RecordingApi());
      m.state!
        ..volume = 15
        ..volumeMin = 10
        ..volumeMax = 30
        ..volumeContext = 'sony:headphone:10:30'
        ..volumeTarget = 'headphone';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: VolumeSlider(m))),
      );
      expect(find.text('Volume for Headphones: 15'), findsOneWidget);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(
        slider.semanticFormatterCallback!(20),
        'Volume for Headphones: 20',
      );
      expect(slider.min, 10);
      expect(slider.max, 30);
      await tester.pumpWidget(const SizedBox());
      m.dispose();
    },
  );
}
