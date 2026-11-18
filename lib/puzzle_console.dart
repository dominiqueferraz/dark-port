import 'package:flutter/material.dart';

import 'achievements.dart';
import 'drafting_controls.dart';
import 'drafting_grid.dart';
import 'drafting_theme.dart';
import 'endless_levels.dart';
import 'sheet_style.dart';
import 'solution_stars.dart';

/// The text and optional drawing number supplied by the active game mode.
class PuzzleBrief {
  const PuzzleBrief({
    required this.title,
    this.sheet,
    this.objective,
    this.goal,
    this.notes = const [],
    this.stars = const [],
    this.achievements = const [],
  });

  final String title;
  final String? sheet;
  final String? objective;
  final String? goal;
  final List<String> notes;
  final List<SolutionStar> stars;
  final List<AchievementStatus> achievements;

  bool get hasHint => goal != null || notes.isNotEmpty || stars.isNotEmpty;

  Rect get awardBounds => Rect.fromLTWH(
    5,
    5,
    (stars.length + achievements.length) * PuzzleConsole._awardCell,
    PuzzleConsole._awardCell,
  );
}

/// The mode owns the destinations for leaving and completing a puzzle.
class PuzzleNavigation {
  const PuzzleNavigation({
    required this.backLabel,
    required this.onBack,
    this.backIcon = Icons.arrow_back,
    this.advance,
  });

  final String backLabel;
  final VoidCallback onBack;
  final IconData backIcon;
  final ({String label, IconData icon, VoidCallback onPressed})? advance;
}

/// Shared layout for a playable board and its readings, controls and status.
class PuzzleConsole extends StatelessWidget {
  const PuzzleConsole({
    super.key,
    required this.brief,
    required this.navigation,
    required this.tools,
    required this.playfield,
    required this.readings,
    required this.solved,
    this.failureMessage,
    this.inventory,
    this.canLeave = true,
    this.onHelp,
    this.feedback = const [],
  });

  final PuzzleBrief brief;
  final PuzzleNavigation navigation;
  final ConsoleTools tools;
  final Widget playfield;
  final Widget readings;
  final Widget? inventory;
  final bool solved;
  final String? failureMessage;
  final bool canLeave;
  final VoidCallback? onHelp;
  final List<Widget> feedback;

  static const _awardSize = 16.0;
  static const _awardInset = 4.0;
  static const _awardCell = _awardSize + 2 * _awardInset;

  @override
  Widget build(BuildContext context) => DraftingScaffold(
    balanceVerticalInsets: true,
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      label: brief.title,
      child: LayoutBuilder(
        builder: (context, constraints) => useConsoleColumns(constraints)
            ? _wideLayout(context)
            : _stackedLayout(context),
      ),
    ),
  );

  Widget _stackedLayout(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolbar(context),
            ?inventory,
            const SizedBox(height: 6),
            CustomPaint(
              painter: DraftingSheetFrame(
                context.sheet.ink,
                trim: context.sheet.fineRule,
              ),
              child: Padding(
                padding: DraftingSheetFrame.inset,
                child: _blueprint(context),
              ),
            ),
            const SizedBox(height: 8),
            ?_objective(),
            _ReadingsFrame(child: readings),
            ...feedback,
            if (brief.sheet != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _titleBlock(),
              ),
            if (failureMessage case final message?) ...[
              const SizedBox(height: 6),
              _FailureNotice(message),
            ],
            if (solved && navigation.advance != null) _advanceButton(context),
          ],
        ),
      ),
    ),
  );

  Widget _wideLayout(BuildContext context) {
    return DraftingSheet(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: KeyedSubtree(
              key: const ValueKey('landscape-viewport'),
              child: _blueprint(context),
            ),
          ),
          const SizedBox(width: DraftingSheetFrame.panelGap),
          Expanded(flex: 3, child: _wideControls(context)),
        ],
      ),
    );
  }

  Widget _wideControls(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: draftingGridMargins.top),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 5,
          child: _PanelScroll(
            viewportKey: const ValueKey('landscape-lesson-readings'),
            framed: true,
            child: readings,
          ),
        ),
        const SizedBox(height: 6),
        _toolbar(context),
        ?inventory,
        const SizedBox(height: 6),
        if (brief.sheet != null) ...[_titleBlock(), const SizedBox(height: 6)],
        if (failureMessage case final message?) ...[
          _FailureNotice(message),
          const SizedBox(height: 6),
        ],
        if (_objective() case final objective?)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 72),
            child: SingleChildScrollView(child: objective),
          ),
        if (feedback.isNotEmpty)
          Flexible(
            flex: 2,
            child: _PanelScroll(
              viewportKey: const ValueKey('landscape-lesson-details'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: feedback,
              ),
            ),
          ),
        if (solved && navigation.advance != null) _advanceButton(context),
      ],
    ),
  );

  Widget? _objective() {
    final objective = brief.objective ?? brief.goal;
    if (objective == null) return null;
    return Padding(
      key: const ValueKey('puzzle-objective'),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Text(objective, style: draftingLettering(12, spacing: .3)),
    );
  }

  Widget _titleBlock() => Semantics(
    key: solved ? const ValueKey('lesson-complete') : null,
    liveRegion: solved,
    label: solved ? 'Complete' : null,
    child: DraftingTitleBlock(
      title: brief.title,
      sheet: brief.sheet!,
      status: switch ((solved, failureMessage != null)) {
        (_, true) => DraftingStatus.failed,
        (true, false) => DraftingStatus.approved,
        _ => DraftingStatus.inProgress,
      },
    ),
  );

  Widget _blueprint(BuildContext context) {
    if (brief.stars.isEmpty && brief.achievements.isEmpty) return playfield;
    final sheet = context.sheet;
    return Stack(
      children: [
        playfield,
        Positioned(
          left: draftingGridMargins.left + brief.awardBounds.left,
          top: draftingGridMargins.top + brief.awardBounds.top,
          child: Material(
            key: const ValueKey('blueprint-awards'),
            color: sheet.paper,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: sheet.ink, width: .9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (brief.stars.isNotEmpty) _starButton(context),
                for (final achievement in brief.achievements)
                  _achievementButton(context, achievement),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _starButton(BuildContext context) => Semantics(
    label: 'Solution Stars',
    value: solutionStarProgress(brief.stars),
    hint: 'Show star conditions',
    child: TextButton(
      key: const ValueKey('puzzle-solution-stars'),
      onPressed: canLeave ? () => _showHint(context) : null,
      style: _blueprintButtonStyle(context),
      child: ExcludeSemantics(
        child: SolutionStars(
          stars: brief.stars,
          size: _awardSize,
          spacing: 2 * _awardInset,
        ),
      ),
    ),
  );

  ButtonStyle _blueprintButtonStyle(BuildContext context) =>
      TextButton.styleFrom(
        foregroundColor: context.sheet.ink,
        minimumSize: const Size.square(_awardCell),
        padding: const EdgeInsets.symmetric(horizontal: _awardInset),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(),
      );

  Widget _achievementButton(BuildContext context, AchievementStatus status) =>
      Semantics(
        label: status.achievement.title,
        value: status.earned ? 'Earned' : 'Unearned',
        hint: 'Show achievement condition',
        child: Tooltip(
          message: status.achievement.title,
          excludeFromSemantics: true,
          child: TextButton(
            key: ValueKey('puzzle-achievement-${status.achievement.name}'),
            onPressed: canLeave
                ? () => _showAchievement(context, status)
                : null,
            style: _blueprintButtonStyle(context),
            child: AchievementIcon(status: status, size: _awardSize),
          ),
        ),
      );

  void _showAchievement(BuildContext context, AchievementStatus status) {
    final sheet = context.sheet;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: sheet.paper,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: sheet.ink, width: 1.6),
        ),
        scrollable: true,
        icon: AchievementIcon(status: status, size: 28),
        title: Text(status.achievement.title, style: draftingLettering(16)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(status.achievement.condition, style: draftingLettering(13)),
            Text(
              status.earned ? 'EARNED' : 'UNEARNED',
              style: draftingLettering(
                10,
                color: status.earned ? sheet.stamp : sheet.faint,
                spacing: .7,
              ),
            ),
          ],
        ),
        actions: [
          consoleButton(
            tooltip: 'Close achievement',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context) => DecoratedBox(
    key: const ValueKey('lesson-toolbar'),
    decoration: BoxDecoration(
      border: Border.all(color: context.sheet.ink, width: .9),
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: consoleButton(
              tooltip: navigation.backLabel,
              onPressed: canLeave ? navigation.onBack : null,
              icon: Icon(navigation.backIcon),
            ),
          ),
          const DraftingCellDivider(),
          Expanded(flex: 3, child: tools),
          const DraftingCellDivider(),
          Expanded(
            child: consoleButton(
              tooltip: 'Hint',
              onPressed: brief.hasHint && canLeave
                  ? () => _showHint(context)
                  : null,
              icon: const Icon(Icons.lightbulb_outline),
            ),
          ),
          if (onHelp case final help?) ...[
            const DraftingCellDivider(),
            Expanded(
              child: consoleButton(
                tooltip: 'Parts guide',
                onPressed: help,
                icon: const Icon(Icons.help_outline),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _advanceButton(BuildContext context) {
    final action = navigation.advance!;
    return OutlinedButton.icon(
      key: const ValueKey('lesson-advance'),
      onPressed: canLeave ? action.onPressed : null,
      icon: Icon(action.icon, size: 18),
      label: Text(action.label, style: draftingLettering(12, spacing: .3)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        shape: const RoundedRectangleBorder(),
        side: BorderSide(color: context.sheet.ink, width: .9),
      ),
    );
  }

  void _showHint(BuildContext context) {
    final sheet = context.sheet;
    final hasStars = brief.stars.isNotEmpty;
    Text heading(String text) => Text(
      text,
      style: draftingLettering(10, color: sheet.faint, spacing: 1.6),
    );
    TextStyle body(double size) =>
        draftingLettering(size, color: sheet.ink, spacing: .3);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: sheet.paper,
        insetPadding: hasStars
            ? const EdgeInsets.symmetric(horizontal: 40, vertical: 16)
            : null,
        iconPadding: hasStars ? const EdgeInsets.fromLTRB(24, 14, 24, 2) : null,
        contentPadding: hasStars
            ? const EdgeInsets.fromLTRB(24, 8, 24, 8)
            : null,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: sheet.ink, width: 1.6),
        ),
        scrollable: true,
        icon: Icon(Icons.lightbulb_outline, color: sheet.ink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (brief.goal case final goal?) ...[
              heading('GOAL'),
              const SizedBox(height: 6),
              Text(goal, style: body(14)),
              if (brief.notes.isNotEmpty) const SizedBox(height: 16),
            ],
            if (brief.notes.isNotEmpty) ...[
              heading('HOW IT WORKS'),
              const SizedBox(height: 6),
              for (final note in brief.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('–  ', style: body(13)),
                      Expanded(child: Text(note, style: body(13))),
                    ],
                  ),
                ),
            ],
            if (brief.stars.isNotEmpty) ...[
              if (brief.goal != null || brief.notes.isNotEmpty)
                Divider(
                  key: const ValueKey('solution-stars-divider'),
                  height: 24,
                  thickness: 1,
                  color: sheet.ink,
                ),
              heading('SOLUTION STARS'),
              const SizedBox(height: 8),
              for (final star in brief.stars)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SolutionStarIcon(earned: star.earned, size: 18),
                      Expanded(child: Text(star.condition, style: body(13))),
                    ],
                  ),
                ),
            ],
          ],
        ),
        actions: [
          consoleButton(
            tooltip: 'Close hint',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _FailureNotice extends StatelessWidget {
  const _FailureNotice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final red = context.sheet.stamp;
    return Semantics(
      key: const ValueKey('puzzle-failure-notice'),
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: red),
          color: red.withValues(alpha: .07),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            spacing: 7,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: red),
              Expanded(
                child: Text(
                  message,
                  style: draftingLettering(12, color: red, spacing: .2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingsFrame extends StatelessWidget {
  const _ReadingsFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      border: Border.all(color: context.sheet.ink, width: 1.2),
    ),
    child: child,
  );
}

class _PanelScroll extends StatefulWidget {
  const _PanelScroll({
    required this.viewportKey,
    required this.child,
    this.framed = false,
  });

  final Key viewportKey;
  final Widget child;
  final bool framed;

  @override
  State<_PanelScroll> createState() => _PanelScrollState();
}

class _PanelScrollState extends State<_PanelScroll> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      thickness: widget.framed ? 3 : null,
      child: SingleChildScrollView(
        key: widget.viewportKey,
        controller: _scroll,
        child: widget.child,
      ),
    );
    return widget.framed ? _ReadingsFrame(child: content) : content;
  }
}
