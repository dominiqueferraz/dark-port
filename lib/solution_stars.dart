import 'package:flutter/material.dart';

import 'endless_levels.dart';
import 'sheet_style.dart';

String solutionStarProgress(List<SolutionStar> stars) {
  final earned = stars.where((star) => star.earned).length;
  final total = stars.length;
  return '$earned of $total Solution Star${total == 1 ? '' : 's'}';
}

class SolutionStarIcon extends StatelessWidget {
  const SolutionStarIcon({super.key, required this.earned, required this.size});

  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    earned ? Icons.star : Icons.star_border,
    color: earned ? context.sheet.stamp : context.sheet.ink,
    semanticLabel: earned ? 'Earned star' : 'Unearned star',
    size: size,
  );
}

class SolutionStars extends StatelessWidget {
  const SolutionStars({
    super.key,
    required this.stars,
    this.size = 16,
    this.spacing = 2,
  });

  final List<SolutionStar> stars;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: spacing,
    children: [
      for (final star in stars)
        SolutionStarIcon(earned: star.earned, size: size),
    ],
  );
}
