import 'dart:io';

import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test/support/tutorial_walkthrough.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgets('native walkthrough completes the tutorial and replays a board', (
    tester,
  ) async {
    final directory = await getApplicationSupportDirectory();
    final saveFile = File('${directory.path}/onboarding-check.json');
    if (await saveFile.exists()) await saveFile.delete();
    try {
      await playTutorial(
        tester,
        makeStore: () => GameStore(locate: () async => saveFile),
        capture: (name) async {
          await tester.pumpAndSettle();
          await tester.pump();
          await tester.pump();
          await binding.takeScreenshot(name);
        },
      );
    } finally {
      if (await saveFile.exists()) await saveFile.delete();
    }
  });
}
