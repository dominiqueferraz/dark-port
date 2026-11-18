import 'dart:io';

import 'package:dark_port/audio_settings.dart';
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

  test(
    'legacy appearance loads and rapid changes persist the last choice',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'dark-port-settings-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/settings.json');
      final store = SettingsStore(locate: () async => file);
      expect(await store.load(), const SheetLookChoice());
      await file.writeAsString('{"style":"blueprint","symbols":"pictogram"}');
      final legacy = await store.load();
      expect(legacy.style, SheetStyle.blueprint);
      expect(legacy.symbols, PartSymbols.pictogram);
      expect(legacy.audio, const AudioSettings());

      const finalChoice = SheetLookChoice(
        style: SheetStyle.aged,
        symbols: PartSymbols.pictogram,
        audio: AudioSettings(
          masterVolume: .8,
          musicVolume: .5,
          effectsVolume: .25,
          effectsEnabled: false,
        ),
      );
      await Future.wait([
        store.write(const SheetLookChoice(style: SheetStyle.blueprint)),
        store.write(finalChoice),
      ]);
      final saved = await SettingsStore(locate: () async => file).load();
      expect(saved, finalChoice);
      expect(saved.audio.musicGain, .4);
      expect(saved.audio.effectsGain, 0);
      expect(saved.audio.copyWith(effectsEnabled: true).effectsGain, .2);
    },
  );

  testWidgets('audio sliders and ticks update independent settings', (
    tester,
  ) async {
    var choice = const SheetLookChoice();
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => SheetLook(
          choice: choice,
          onChanged: (next) => setState(() => choice = next),
          child: const MaterialApp(home: SettingsScreen()),
        ),
      ),
    );
    final sliders = find.byType(Slider);
    for (final (index, value) in [(0, .8), (1, .5), (2, .25)]) {
      tester.widget<Slider>(sliders.at(index)).onChanged!(value);
      await tester.pump();
    }
    final effects = find.bySemanticsLabel('Effects enabled');
    await tester.ensureVisible(effects);
    await tester.tap(effects);
    await tester.pumpAndSettle();
    expect(choice.audio.musicGain, .4);
    expect(choice.audio.effectsGain, 0);
    expect(choice.audio.effectsVolume, .25);
    expect(
      tester.getSemantics(effects),
      matchesSemantics(
        label: 'Effects enabled',
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(effects);
    await tester.pumpAndSettle();
    expect(choice.audio.effectsGain, .2);
  });
}
