import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doomscrolling_ui/src/app.dart';
import 'package:doomscrolling_ui/src/design.dart';
import 'package:doomscrolling_ui/src/platform_settings.dart';
import 'package:doomscrolling_ui/src/website.dart';

import 'settings_test.dart' show FakeSettings;

void main() {
  testWidgets(
    'app switches persist through native gateway and appearance changes',
    (tester) async {
      tester.view.reset();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final gateway = FakeSettings();
      final controller = ProtectionController(gateway);
      addTearDown(controller.dispose);
      await tester.pumpWidget(DoomscrollingApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Protection is on'), findsOneWidget);
      final master = find.byType(CupertinoSwitch).first;
      await tester.ensureVisible(master);
      await tester.tap(master);
      await tester.pumpAndSettle();
      expect(gateway.state.enabled, false);
      expect(find.text('Protection paused'), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(gateway.state.themeMode, 'dark');
      expect(
        Theme.of(tester.element(find.text('Make it yours.'))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(320, 780), const Size(1200, 900)]) {
    testWidgets('website renders and routes at ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final links = <String>[];
      await tester.pumpWidget(
        DoomscrollingWebsite(initialTheme: 'light', openUrl: links.add),
      );
      await tester.pumpAndSettle();
      final download = find.text('Download for Android');
      await tester.ensureVisible(download);
      await tester.tap(download);
      expect(links, ['/download']);
      expect(tester.takeException(), isNull);
      final source = find.text('Explore the project');
      await tester.ensureVisible(source);
      await tester.tap(source);
      await tester.pumpAndSettle();
      expect(find.text('Open source.\nOn your side.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('reminder shows and clears without replacing selected preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(Brightness.light),
        home: const Scaffold(body: Center(child: ReminderDemo())),
      ),
    );
    await tester.tap(find.text('Try the reminder'));
    await tester.pump();
    expect(find.text('You are doom scrolling'), findsOneWidget);
    expect(find.text('Stay for the moment.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('You are doom scrolling'), findsNothing);
  });
  testWidgets('large type fits the app without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: FocusDashboard(
                state: ProtectionState(
                  engineAvailable: true,
                  serviceEnabled: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
