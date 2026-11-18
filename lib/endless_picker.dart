import 'package:flutter/material.dart';

import 'drafting_controls.dart';
import 'drafting_theme.dart';
import 'drawing_path.dart';
import 'endless_levels.dart';
import 'tutorial_progress.dart';

class EndlessGroups extends StatelessWidget {
  const EndlessGroups({super.key, required this.onBack, required this.onOpen});

  final VoidCallback onBack;
  final ValueChanged<EndlessGroup> onOpen;

  @override
  Widget build(BuildContext context) => _EndlessRegister(
    title: 'ENDLESS',
    onBack: onBack,
    path: DrawingPath(
      scrollKey: const ValueKey('endless-group-line'),
      main: EndlessGroup.values,
      entries: {
        for (final group in EndlessGroup.values)
          group: DrawingPathEntry(
            key: ValueKey('endless-group-${group.number}'),
            title: group.title,
            number: '${group.number}',
            kind: 'GROUP',
            status: 'Open',
            icon: Icons.arrow_forward,
            onOpen: () => onOpen(group),
          ),
      },
    ),
  );
}

class EndlessPicker extends StatelessWidget {
  const EndlessPicker({
    super.key,
    required this.group,
    required this.onBack,
    required this.onOpen,
    required this.progress,
    this.focus,
  });

  final EndlessGroup group;
  final VoidCallback onBack;
  final ValueChanged<EndlessLevel> onOpen;
  final TutorialProgress? progress;
  final EndlessLevel? focus;

  @override
  Widget build(BuildContext context) {
    final levels = group.levels;
    final byNumber = {for (final level in levels) level.number: level};
    return _EndlessRegister(
      title: group.title.toUpperCase(),
      caption: 'GROUP ${group.number}',
      backLabel: 'Back to Endless groups',
      onBack: onBack,
      path: DrawingPath(
        scrollKey: const ValueKey('endless-level-line'),
        main: levels.where((level) => level.variantOf == null).toList(),
        branches: {
          for (final level in levels)
            if (level.variantOf case final parent?) level: byNumber[parent]!,
        },
        entries: {for (final level in levels) level: _entry(level)},
        focus: focus,
      ),
    );
  }

  DrawingPathEntry _entry(EndlessLevel level) {
    final unlocked = level.lesson != null;
    final saved = progress?.endlessBoards[level.lesson?.id];
    final result = progress?.resultFor(level);
    final complete = saved?.solved == true;
    final (status, icon) = !unlocked
        ? ('Planned', Icons.lock_outline)
        : complete
        ? ('Replay', Icons.replay)
        : saved != null
        ? ('Resume', Icons.play_circle_outline)
        : ('Start', Icons.play_arrow);
    final parent = level.variantOf;
    final number = group.sheetNumber(level);
    return DrawingPathEntry(
      key: ValueKey('endless-$number'),
      title: level.title,
      number: number,
      kind: parent == null ? 'PUZZLE' : 'VARIANT',
      status: status,
      icon: icon,
      onOpen: unlocked ? () => onOpen(level) : null,
      branchHint: parent == null ? null : 'Variant of ${group.number}.$parent',
      stars: level.starsFor(result?.stars ?? const {}),
      current: unlocked && !complete && parent == null,
      complete: complete,
    );
  }
}

class _EndlessRegister extends StatelessWidget {
  const _EndlessRegister({
    required this.title,
    required this.onBack,
    required this.path,
    this.caption,
    this.backLabel = 'Return to title',
  });

  final String title;
  final VoidCallback onBack;
  final Widget path;
  final String? caption;
  final String backLabel;

  @override
  Widget build(BuildContext context) => DraftingScaffold(
    child: DraftingSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConsoleHeader(
            title: title,
            caption: caption,
            backLabel: backLabel,
            onBack: onBack,
          ),
          const SizedBox(height: 12),
          Expanded(child: path),
        ],
      ),
    ),
  );
}
