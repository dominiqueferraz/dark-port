import 'dart:io';

import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test/endless_routing_test.dart' show playRoutingBoards;
import '../test/endless_test.dart' show playNewEndlessBoards;
import '../test/handoff_test.dart' show playHandoffBoards;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  for (final (range, play) in [
    ('1.2–1.5', playNewEndlessBoards),
    ('1.6–1.10', playRoutingBoards),
    ('1.11–1.20', playHandoffBoards),
  ]) {
    testWidgets('native walkthrough solves Endless $range', (tester) async {
      final support = await getApplicationSupportDirectory();
      final temp = await support.createTemp('endless-walkthrough-');
      try {
        final save = File('${temp.path}/journey.json');
        await play(tester, GameStore(locate: () async => save));
      } finally {
        await temp.delete(recursive: true);
      }
    });
  }
}
