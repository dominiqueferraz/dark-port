import 'package:flutter/material.dart';

import 'endless_levels.dart';
import 'sheet_style.dart';
import 'tutorial_progress.dart';

enum Achievement {
  firstSignal(
    'First Signal',
    'Solve any Endless puzzle.',
    Icons.flag_outlined,
    Icons.flag,
  ),
  bothRoutes(
    'Both Routes',
    'Earn both Solution Stars in Night Lights.',
    Icons.explore_outlined,
    Icons.explore,
  ),
  fourCableRecord(
    'Four-Cable Record',
    'Solve Night Lights with exactly four installed patch leads.',
    Icons.emoji_events_outlined,
    Icons.emoji_events,
    blueprint: EndlessLevel.nightLights,
  );

  const Achievement(
    this.title,
    this.condition,
    this.unearnedIcon,
    this.earnedIcon, {
    this.blueprint,
  });

  final String title;
  final String condition;
  final IconData unearnedIcon;
  final IconData earnedIcon;
  final EndlessLevel? blueprint;

  bool isEarned(TutorialProgress? progress) => switch (this) {
    firstSignal =>
      progress?.endlessBoards.values.any((board) => board.solved) ?? false,
    bothRoutes =>
      progress?.resultFor(EndlessLevel.nightLights)?.stars.length ==
          EndlessLevel.nightLights.solutionIds.length,
    fourCableRecord =>
      progress?.resultFor(EndlessLevel.nightLights)?.fourCableRecord == true,
  };
}

typedef AchievementStatus = ({Achievement achievement, bool earned});

class AchievementIcon extends StatelessWidget {
  const AchievementIcon({super.key, required this.status, this.size = 24});

  final AchievementStatus status;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Icon(
      status.earned
          ? status.achievement.earnedIcon
          : status.achievement.unearnedIcon,
      color: status.earned ? context.sheet.stamp : context.sheet.ink,
      size: size,
    ),
  );
}
