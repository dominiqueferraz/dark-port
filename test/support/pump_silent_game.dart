import 'package:dark_port/main.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpSilentGame(WidgetTester tester, GameStore store) =>
    tester.pumpWidget(DarkPort(store: store, audioEnabled: false));
