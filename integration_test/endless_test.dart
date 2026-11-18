import 'dart:io';

import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test/endless_test.dart' show playNewEndlessBoards;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgets('native walkthrough solves Endless 1.2–1.5', (tester) async {
    final support = await getApplicationSupportDirectory();
    final temp = await support.createTemp('endless-walkthrough-');
    try {
      final save = File('${temp.path}/journey.json');
      await playNewEndlessBoards(tester, GameStore(locate: () async => save));
    } finally {
      await temp.delete(recursive: true);
    }
  });
}
