import 'dart:io';

import 'package:dark_port/part_symbols.dart';
import 'package:dark_port/settings_screen.dart';
import 'package:dark_port/sheet_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every appearance option has space to paint its preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      SheetLook(
        choice: const SheetLookChoice(),
        onChanged: (_) {},
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    final previews = find.descendant(
      of: find.byType(InkWell),
      matching: find.byType(SheetBackground),
    );
    expect(
      previews,
      findsNWidgets(SheetStyle.all.length + PartSymbols.all.length),
    );
    for (final preview in previews.evaluate()) {
      expect(
        tester
            .getSize(find.byElementPredicate((element) => element == preview))
            .width,
        greaterThan(0),
      );
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Paper')),
      matchesSemantics(
        label: 'Paper',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('rapid changes persist the last style and symbol set', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dark-port-settings-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/settings.json');
    final store = SettingsStore(locate: () async => file);
    expect(await store.load(), const SheetLookChoice());

    const finalChoice = SheetLookChoice(
      style: SheetStyle.aged,
      symbols: PartSymbols.pictogram,
    );
    await Future.wait([
      store.write(const SheetLookChoice(style: SheetStyle.blueprint)),
      store.write(finalChoice),
    ]);
    expect(await SettingsStore(locate: () async => file).load(), finalChoice);
  });
}
