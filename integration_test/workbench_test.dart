import 'dart:io';

import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test/workbench_test.dart' show playWorkbench;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgets('native Workbench tutorial and blueprint reuse', (tester) async {
    final support = await getApplicationSupportDirectory();
    final directory = await support.createTemp('workbench-walkthrough-');
    try {
      final save = File('${directory.path}/journey.json');
      await playWorkbench(tester, GameStore(locate: () async => save));
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
