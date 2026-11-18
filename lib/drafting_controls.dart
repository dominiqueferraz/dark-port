import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'drafting_theme.dart';
import 'sheet_style.dart';

bool useConsoleColumns(BoxConstraints constraints) =>
    constraints.maxWidth >= 540 && constraints.maxWidth > constraints.maxHeight;

class DraftingScaffold extends StatelessWidget {
  const DraftingScaffold({
    super.key,
    required this.child,
    this.balanceVerticalInsets = false,
  });

  final Widget child;
  final bool balanceVerticalInsets;

  EdgeInsets _minimumInsets(BuildContext context) {
    if (!balanceVerticalInsets ||
        MediaQuery.orientationOf(context) != Orientation.landscape) {
      return EdgeInsets.zero;
    }
    final insets = MediaQuery.paddingOf(context);
    return EdgeInsets.symmetric(vertical: math.max(insets.top, insets.bottom));
  }

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    final overlays = sheet.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlays.copyWith(systemNavigationBarColor: sheet.paper),
      child: Scaffold(
        backgroundColor: sheet.paper,
        body: DraftingPaper(
          child: SafeArea(minimum: _minimumInsets(context), child: child),
        ),
      ),
    );
  }
}

const consoleButtonSize = Size.square(44);

Widget consoleButton({
  Key? key,
  required String tooltip,
  required VoidCallback? onPressed,
  required Widget icon,
  bool emphasized = false,
}) => Builder(
  builder: (context) {
    final sheet = context.sheet;
    return IconButton.filled(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      style: IconButton.styleFrom(
        minimumSize: Size(0, consoleButtonSize.height),
        maximumSize: Size(double.infinity, consoleButtonSize.height),
        iconSize: 20,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: emphasized ? sheet.paper : sheet.ink,
        backgroundColor: emphasized ? sheet.ink : Colors.transparent,
        disabledForegroundColor: emphasized
            ? sheet.ink
            : sheet.faint.withValues(alpha: .6),
        disabledBackgroundColor: emphasized
            ? sheet.ink.withValues(alpha: .14)
            : Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
    );
  },
);

class ConsoleHeader extends StatelessWidget {
  const ConsoleHeader({
    super.key,
    required this.title,
    this.caption,
    this.onBack,
    this.backLabel = 'Return to title',
  });

  final String title;
  final String? caption;
  final VoidCallback? onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sheet.ink, width: 1.2)),
      ),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: sheet.ink, width: .9),
            ),
            child: SizedBox.fromSize(
              size: consoleButtonSize,
              child: consoleButton(
                tooltip: backLabel,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: draftingLettering(16, spacing: 3)),
            ),
          ),
          if (caption case final caption?)
            Text(
              caption,
              style: draftingLettering(10, color: sheet.faint, spacing: 1.6),
            ),
        ],
      ),
    );
  }
}

class ConsoleTools extends StatelessWidget {
  const ConsoleTools({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.onReset,
    this.undoKey,
    this.redoKey,
  });

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onReset;
  final Key? undoKey;
  final Key? redoKey;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: consoleButton(
          key: undoKey,
          tooltip: 'Undo',
          onPressed: onUndo,
          icon: const Icon(Icons.undo),
        ),
      ),
      const DraftingCellDivider(),
      Expanded(
        child: consoleButton(
          key: redoKey,
          tooltip: 'Redo',
          onPressed: onRedo,
          icon: const Icon(Icons.redo),
        ),
      ),
      const DraftingCellDivider(),
      Expanded(
        child: consoleButton(
          tooltip: 'Reset room',
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt),
        ),
      ),
    ],
  );
}
