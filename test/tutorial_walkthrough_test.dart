import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_store.dart';
import 'support/tutorial_walkthrough.dart';

void main() {
  testWidgets(
    'plays every tutorial lesson and the optional branch in landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(874, 402);
      tester.view.padding = const FakeViewPadding(
        left: 62,
        right: 62,
        bottom: 21,
      );
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      final store = MemoryStore();
      await playTutorial(tester, makeStore: () => store, capture: (_) async {});
    },
  );
}
