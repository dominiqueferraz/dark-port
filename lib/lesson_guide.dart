import 'package:flutter/material.dart';

import 'drafting_theme.dart';
import 'sheet_style.dart';

class LessonGuide extends StatefulWidget {
  const LessonGuide({
    super.key,
    required this.title,
    required this.goal,
    required this.notes,
    required this.onStart,
  });

  final String title;
  final String? goal;
  final List<String> notes;
  final VoidCallback onStart;

  @override
  State<LessonGuide> createState() => _LessonGuideState();
}

class _LessonGuideState extends State<LessonGuide> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    const textInsets = EdgeInsets.only(left: 16, right: 23);
    const goalGap = 8.0;
    final ruleColor = sheet.faint.withValues(alpha: .65);

    return Material(
      color: sheet.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: sheet.ink, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: RawScrollbar(
                controller: _scroll,
                thumbVisibility: true,
                thickness: 3,
                crossAxisMargin: 16,
                thumbColor: ruleColor,
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: textInsets,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: goalGap,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                widget.title,
                                style: draftingLettering(
                                  17,
                                  color: sheet.ink,
                                  spacing: .4,
                                ),
                              ),
                            ),
                            if (widget.goal case final goal?)
                              Text(
                                goal,
                                style: draftingLettering(
                                  23,
                                  color: sheet.ink,
                                  spacing: .3,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.notes.isNotEmpty) ...[
                        if (widget.goal != null)
                          Divider(
                            height: 2 * goalGap + 1,
                            thickness: 1,
                            color: ruleColor,
                          )
                        else
                          const SizedBox(height: goalGap),
                        Padding(
                          padding: textInsets,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (index, note)
                                  in widget.notes.indexed) ...[
                                if (index > 0)
                                  SizedBox(
                                    width: 22,
                                    child: Divider(
                                      height: 17,
                                      thickness: 1,
                                      color: ruleColor,
                                    ),
                                  ),
                                Text(
                                  note,
                                  style: draftingLettering(
                                    14,
                                    color: sheet.ink,
                                    spacing: .2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  autofocus: true,
                  onPressed: widget.onStart,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    'Start lesson',
                    style: draftingLettering(14, spacing: .3),
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
