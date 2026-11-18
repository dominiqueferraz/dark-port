import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_settings.dart';
import 'part_symbols.dart';

/// A complete look for the drawn screens: paper, inks and paper texture.
/// Every drawing asks the active style for its colours, so styles can be
/// swapped without touching what is drawn.
class SheetStyle {
  const SheetStyle({
    required this.id,
    required this.name,
    required this.paper,
    required this.ink,
    required this.faint,
    required this.grid,
    required this.beam,
    required this.alarmBeam,
    required this.stamp,
    required this.approval,
    required this.brightness,
    required this.fineRule,
    this.surfaceAsset,
    this.inkWearAsset,
    this.inkSoftness = 0,
  });

  final String id;
  final String name;

  /// The sheet colour, also used to knock out lines behind parts.
  final Color paper;
  final Color ink;
  final Color faint;
  final Color grid;
  final Color beam;
  final Color alarmBeam;
  final Color stamp;
  final Color approval;
  final Brightness brightness;
  final Color fineRule;
  final String? surfaceAsset;
  final String? inkWearAsset;
  final double inkSoftness;

  static const light = SheetStyle(
    id: 'light',
    name: 'Light',
    paper: Color(0xfff3f0e7),
    ink: Color(0xff23303f),
    faint: Color(0xff596575),
    grid: Color(0xffc9cdd2),
    beam: Color(0xffae3823),
    alarmBeam: Color(0xff895811),
    stamp: Color(0xffb32e28),
    approval: Color(0xff276339),
    brightness: Brightness.light,
    fineRule: Color(0xff23303f),
  );

  static const blueprint = SheetStyle(
    id: 'blueprint',
    name: 'Blueprint',
    paper: Color(0xff37558a),
    ink: Color(0xffe1eaf8),
    faint: Color(0xff9ab0d3),
    grid: Color(0xff426394),
    beam: Color(0xffffc857),
    alarmBeam: Color(0xff8be0c0),
    stamp: Color(0xffffac98),
    approval: Color(0xffa8f0b1),
    brightness: Brightness.dark,
    fineRule: Color(0xff899cc0),
    surfaceAsset: 'assets/drafting/surfaces/blueprint.png',
    inkWearAsset: 'assets/drafting/surfaces/blueprint-ink-wear.png',
    inkSoftness: .17,
  );

  static const paperSheet = SheetStyle(
    id: 'paper',
    name: 'Paper',
    paper: Color(0xffebdec2),
    ink: Color(0xff2b2f37),
    faint: Color(0xff8a8272),
    grid: Color(0xffcdbb94),
    beam: Color(0xffb54c34),
    alarmBeam: Color(0xff895811),
    stamp: Color(0xffb32e28),
    approval: Color(0xff276339),
    brightness: Brightness.light,
    fineRule: Color(0xff89847b),
    surfaceAsset: 'assets/drafting/surfaces/paper.png',
  );

  static const aged = SheetStyle(
    id: 'aged',
    name: 'Aged paper',
    paper: Color(0xffe4dbc6),
    ink: Color(0xff2b2f37),
    faint: Color(0xff928875),
    grid: Color(0xffc5b99e),
    beam: Color(0xffb64f39),
    alarmBeam: Color(0xff78521a),
    stamp: Color(0xff792019),
    approval: Color(0xff25542e),
    brightness: Brightness.light,
    fineRule: Color(0xff938f85),
    surfaceAsset: 'assets/drafting/surfaces/aged.png',
    inkWearAsset: 'assets/drafting/surfaces/aged-ink-wear.png',
    inkSoftness: .20,
  );

  static const all = [light, blueprint, paperSheet, aged];
  static const fallback = paperSheet;

  static SheetStyle byId(String? id) =>
      all.firstWhere((style) => style.id == id, orElse: () => fallback);
}

/// Player preferences saved together in settings.
@immutable
class SheetLookChoice {
  const SheetLookChoice({
    this.style = SheetStyle.fallback,
    this.symbols = PartSymbols.fallback,
    this.audio = const AudioSettings(),
  });

  final SheetStyle style;
  final PartSymbols symbols;
  final AudioSettings audio;

  SheetLookChoice copyWith({
    SheetStyle? style,
    PartSymbols? symbols,
    AudioSettings? audio,
  }) => SheetLookChoice(
    style: style ?? this.style,
    symbols: symbols ?? this.symbols,
    audio: audio ?? this.audio,
  );

  Map<String, Object?> toJson() => {
    'style': style.id,
    'symbols': symbols.id,
    'audio': audio.toJson(),
  };

  factory SheetLookChoice.fromJson(Map<String, Object?> json) =>
      SheetLookChoice(
        style: SheetStyle.byId(json['style'] as String?),
        symbols: PartSymbols.byId(json['symbols'] as String?),
        audio: switch (json['audio']) {
          final Map<String, Object?> sound => AudioSettings.fromJson(sound),
          _ => const AudioSettings(),
        },
      );

  @override
  bool operator ==(Object other) =>
      other is SheetLookChoice &&
      other.style == style &&
      other.symbols == symbols &&
      other.audio == audio;

  @override
  int get hashCode => Object.hash(style, symbols, audio);
}

/// Makes the chosen look available to every screen and dialog.
class SheetLook extends InheritedWidget {
  const SheetLook({
    super.key,
    required this.choice,
    this.onChanged,
    required super.child,
  });

  final SheetLookChoice choice;
  final ValueChanged<SheetLookChoice>? onChanged;

  static SheetLook? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetLook>();

  static SheetLookChoice of(BuildContext context) =>
      _of(context)?.choice ?? const SheetLookChoice();

  static ValueChanged<SheetLookChoice>? changerOf(BuildContext context) =>
      _of(context)?.onChanged;

  @override
  bool updateShouldNotify(SheetLook oldWidget) => choice != oldWidget.choice;
}

extension SheetLookContext on BuildContext {
  SheetStyle get sheet => SheetLook.of(this).style;
  PartSymbols get symbols => SheetLook.of(this).symbols;
}

/// Saves preferences on the device, next to the game save.
class SettingsStore {
  SettingsStore({Future<File> Function()? locate})
    : _locate = locate ?? _settingsFile;

  final Future<File> Function() _locate;
  Future<void> _pending = Future.value();

  static Future<File> _settingsFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/settings.json');
  }

  /// The saved preferences, or defaults if nothing usable is saved.
  Future<SheetLookChoice> load() async {
    await _pending;
    try {
      final file = await _locate();
      if (!await file.exists()) return const SheetLookChoice();
      return SheetLookChoice.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, Object?>,
      );
    } on Object {
      return const SheetLookChoice();
    }
  }

  Future<void> write(SheetLookChoice choice) {
    final operation = _pending.then((_) async {
      final file = await _locate();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(choice.toJson()), flush: true);
      await temporary.rename(file.path);
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}

/// Paints a sheet and the fine variation in its printed ink.
class SheetBackground extends StatelessWidget {
  const SheetBackground({super.key, required this.style, required this.child});

  final SheetStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = style.surfaceAsset;
    if (surface == null) return ColoredBox(color: style.paper, child: child);

    final wear = style.inkWearAsset;
    final softness = style.inkSoftness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.paper,
        image: DecorationImage(image: AssetImage(surface), fit: BoxFit.fill),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (softness > 0)
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: softness,
                sigmaY: softness - .03,
              ),
              child: child,
            )
          else
            child,
          if (wear != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(wear),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
