import 'package:flutter/material.dart';

import 'achievements.dart';
import 'drafting_theme.dart';
import 'sheet_style.dart';
import 'solution_stars.dart';

Future<void> showPuzzleAwards(
  BuildContext context, {
  required String scenario,
  required List<String> starConditions,
  required List<Achievement> achievements,
}) {
  final sheet = context.sheet;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('puzzle-announcement'),
      backgroundColor: sheet.paper,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: sheet.ink, width: 1.6),
      ),
      scrollable: true,
      title: Text(
        'Awards earned',
        style: draftingLettering(18, color: sheet.ink),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Text(scenario, style: draftingLettering(15, color: sheet.ink)),
          for (final condition in starConditions)
            _Award(
              icon: const SolutionStarIcon(earned: true, size: 22),
              title: 'Solution Star earned',
              condition: condition,
            ),
          for (final achievement in achievements)
            _Award(
              icon: AchievementIcon(
                status: (achievement: achievement, earned: true),
                size: 22,
              ),
              title: 'Achievement earned · ${achievement.title}',
              condition: achievement.condition,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
      ],
    ),
  );
}

class _Award extends StatelessWidget {
  const _Award({
    required this.icon,
    required this.title,
    required this.condition,
  });

  final Widget icon;
  final String title;
  final String condition;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10,
    children: [
      icon,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(title, style: draftingLettering(14, color: context.sheet.ink)),
            Text(
              condition,
              style: draftingLettering(12, color: context.sheet.ink),
            ),
          ],
        ),
      ),
    ],
  );
}
