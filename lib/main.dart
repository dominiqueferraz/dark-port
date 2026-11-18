import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_shell.dart';
import 'sheet_style.dart';
import 'tutorial_progress.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'DINish Condensed',
    ], await rootBundle.loadString('assets/drafting/OFL.txt'));
  });
  runApp(const DarkPort());
}

class DarkPort extends StatefulWidget {
  const DarkPort({super.key, this.store, this.settings});

  final GameStore? store;
  final SettingsStore? settings;

  @override
  State<DarkPort> createState() => _DarkPortState();
}

class _DarkPortState extends State<DarkPort> {
  late final _store = widget.store ?? GameStore();
  late final _settings = widget.settings ?? SettingsStore();
  var _look = const SheetLookChoice();
  var _changed = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      _settings.load().then((look) {
        if (mounted && !_changed) setState(() => _look = look);
      }),
    );
  }

  void _change(SheetLookChoice look) {
    _changed = true;
    setState(() => _look = look);
    // A failed save only loses the choice for the next launch.
    unawaited(_settings.write(look).catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _look.style;
    return SheetLook(
      choice: _look,
      onChanged: _change,
      child: MaterialApp(
        title: 'Dark Port',
        debugShowCheckedModeBanner: false,
        themeAnimationDuration: Duration.zero,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: sheet.ink,
            brightness: sheet.brightness,
            surface: sheet.paper,
            onSurface: sheet.ink,
            onSurfaceVariant: sheet.ink,
            primary: sheet.ink,
            onPrimary: sheet.paper,
            error: sheet.stamp,
            surfaceTint: Colors.transparent,
          ),
        ),
        home: GameShell(store: _store),
      ),
    );
  }
}
