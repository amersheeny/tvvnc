import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_vnc/ui/device_form.dart';
import 'package:tv_vnc/ui/keyboard_page.dart';
import 'package:tv_vnc/ui/privacy_page.dart';
import 'package:tv_vnc/ui/remote_page.dart';
import 'package:tv_vnc/ui/widgets.dart';

import 'navigation_test.dart' as nav;
import 'widget_safety_test.dart' show profile;

class PolicyBundle extends CachingAssetBundle {
  bool fail = true;
  int attempts = 0;

  @override
  Future<ByteData> load(String key) {
    if (key == 'assets/privacy-policy.json') {
      attempts++;
      if (fail) return Future.error(FlutterError('test asset failure'));
    }
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('privacy is readable without a TV or network permission', (
    tester,
  ) async {
    final (model, api) = await nav.mount(tester);
    model.profiles.clear();
    model.networkPermissionDenied = true;
    model.notifyListeners();
    await tester.pumpAndSettle();
    await nav.destination(tester, 'Privacy policy');
    expect(find.byType(PrivacyPage), findsOneWidget);
    expect(find.text('TV VNC Privacy Policy'), findsOneWidget);
    expect(find.byType(NetworkPermissionPanel), findsNothing);
    expect(find.byKey(const ValueKey('tv-menu')), findsNothing);
    expect(find.textContaining('support@apptico.com'), findsWidgets);
    expect(api.connections, isEmpty);
    expect(api.disconnections, isEmpty);
    expect(api.commands, isEmpty);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(DevicesPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy Back returns to Remote without changing connections', (
    tester,
  ) async {
    final (_, api) = await nav.mount(tester);
    await nav.chooseTv(tester, 'TV A');
    await nav.destination(tester, 'Privacy policy');
    expect(find.byType(PrivacyPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RemotePage), findsOneWidget);
    expect(api.connections, ['TV A']);
    expect(api.disconnections, isEmpty);
    expect(api.commands, isEmpty);
  });

  testWidgets('privacy leaves Keyboard through local navigation and returns', (
    tester,
  ) async {
    final (_, api) = await nav.mount(tester);
    await nav.chooseTv(tester, 'TV A');
    await nav.destination(tester, 'Keyboard');
    expect(find.byType(KeyboardPage), findsOneWidget);
    await nav.destination(tester, 'Privacy policy');
    expect(find.byType(PrivacyPage), findsOneWidget);
    expect(find.byType(KeyboardPage), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(KeyboardPage), findsOneWidget);
    expect(api.connections, ['TV A']);
    expect(api.commands, isEmpty);
  });

  testWidgets('changing selected TV clears privacy history as other pages do', (
    tester,
  ) async {
    final (model, _) = await nav.mount(tester);
    await nav.chooseTv(tester, 'TV A');
    await nav.destination(tester, 'Privacy policy');
    model.selected = profile('TV B');
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyPage), findsNothing);
    expect(find.byType(DevicesPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('policy headings remain semantic headings at large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(body: PrivacyPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.text('TV VNC Privacy Policy'))
          .flagsCollection
          .isHeader,
      isTrue,
    );
    expect(find.text('Information the app uses'), findsOneWidget);
    expect(find.text('Connection security'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed policy load is visible and a new visit retries', (
    tester,
  ) async {
    final bundle = PolicyBundle();
    Widget page(int visit) => DefaultAssetBundle(
      bundle: bundle,
      child: MaterialApp(
        home: Scaffold(body: PrivacyPage(key: ValueKey(visit))),
      ),
    );
    await tester.pumpWidget(page(1));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('The privacy policy couldn’t be shown.'),
      findsOneWidget,
    );
    bundle.fail = false;
    await tester.pumpWidget(page(2));
    await tester.pumpAndSettle();
    expect(find.text('TV VNC Privacy Policy'), findsOneWidget);
    expect(bundle.attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
