import 'package:flutter/material.dart';

import 'drafting_controls.dart';
import 'drafting_theme.dart';
import 'drawing_path.dart';
import 'sheet_style.dart';
import 'tutorial.dart';
import 'tutorial_progress.dart';

class TutorialPicker extends StatelessWidget {
  const TutorialPicker({
    super.key,
    required this.progress,
    required this.onBack,
    required this.onOpen,
    this.focusLesson,
  });

  final TutorialProgress progress;
  final VoidCallback onBack;
  final ValueChanged<TutorialLesson> onOpen;
  final TutorialLesson? focusLesson;

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    final completed = requiredLessons.where(progress.isComplete).length;
    final index = requiredLessons.indexWhere(
      (lesson) => !progress.isComplete(lesson),
    );
    final previous = index > 0 ? requiredLessons[index - 1] : null;
    return DraftingScaffold(
      child: DraftingSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConsoleHeader(
              title: 'TUTORIAL',
              caption: 'DRAWING REGISTER',
              onBack: onBack,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
              child: Text(
                completed == requiredLessons.length
                    ? 'ALL SHEETS APPROVED'
                    : '$completed OF ${requiredLessons.length} APPROVED',
                style: draftingLettering(12, color: sheet.faint, spacing: 1.4),
              ),
            ),
            Expanded(
              child: DrawingPath(
                scrollKey: const ValueKey('tutorial-path-scroll'),
                main: requiredLessons,
                branches: practiceLessons,
                headings: {
                  for (final (i, lesson) in requiredLessons.indexed)
                    if (i == 0 ||
                        lesson.runtimeType !=
                            requiredLessons[i - 1].runtimeType)
                      lesson: lesson is OpticalLesson
                          ? 'LIGHT'
                          : 'WIRED SIGNALS',
                },
                entries: {
                  for (final lesson in lessonsById.values)
                    lesson: _entry(lesson),
                },
                focus:
                    focusLesson ??
                    (index == -1
                        ? requiredLessons.last
                        : requiredLessons[index]),
                focusFrom:
                    focusLesson == null &&
                        practiceLessons.containsValue(previous)
                    ? previous
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DrawingPathEntry _entry(TutorialLesson lesson) {
    final unlocked = progress.isUnlocked(lesson);
    final complete = progress.isComplete(lesson);
    final practice = practiceLessons.containsKey(lesson);
    final hasDraft = progress.boards.containsKey(lesson.id);
    final (status, icon) = !unlocked
        ? ('Locked', Icons.lock_outline)
        : complete
        ? ('Replay', Icons.replay)
        : hasDraft
        ? ('Resume', Icons.play_circle_outline)
        : ('Start', Icons.play_arrow);
    return DrawingPathEntry(
      key: ValueKey('lesson-${lesson.id}'),
      title: lesson.title,
      number: sheetNumber(lesson),
      kind: practice
          ? 'PRACTICE'
          : lesson is OpticalLesson
          ? 'OPTICAL'
          : 'WIRED',
      status: status,
      icon: icon,
      onOpen: unlocked ? () => onOpen(lesson) : null,
      branchHint: practice ? 'Practice branch' : null,
      current: unlocked && !complete && !practice,
      complete: complete,
    );
  }
}
