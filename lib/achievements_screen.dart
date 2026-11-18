import 'package:flutter/material.dart';

import 'achievements.dart';
import 'drafting_controls.dart';
import 'drafting_theme.dart';
import 'sheet_style.dart';
import 'tutorial_progress.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.progress});

  final TutorialProgress? progress;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      for (final achievement in Achievement.values)
        (achievement: achievement, earned: achievement.isEarned(progress)),
    ];
    final earned = statuses.where((status) => status.earned).length;
    return DraftingScaffold(
      child: DraftingSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConsoleHeader(
              title: 'ACHIEVEMENTS',
              caption: '$earned OF ${statuses.length} EARNED',
              onBack: () => Navigator.of(context).pop(),
              backLabel: 'Return to title',
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: statuses.length,
                    itemBuilder: (context, index) =>
                        _AchievementRow(statuses[index]),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: .75,
                      color: context.sheet.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow(this.status);

  final AchievementStatus status;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    key: ValueKey('achievement-${status.achievement.name}'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Row(
        spacing: 12,
        children: [
          AchievementIcon(status: status, size: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      status.achievement.title,
                      style: draftingLettering(14, spacing: .5),
                    ),
                    Text(
                      status.earned ? 'EARNED' : 'UNEARNED',
                      style: draftingLettering(
                        10,
                        color: status.earned
                            ? context.sheet.stamp
                            : context.sheet.faint,
                        spacing: .7,
                      ),
                    ),
                  ],
                ),
                Text(
                  status.achievement.condition,
                  style: draftingLettering(12, spacing: .2),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
