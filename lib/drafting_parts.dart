import 'package:flutter/material.dart';

import 'drafting_theme.dart';
import 'sheet_style.dart';

/// The ruled parts list shared by every puzzle console.
class DraftingPartsList extends StatelessWidget {
  const DraftingPartsList({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DraftingPartRow.header(),
        for (final (index, row) in rows.indexed)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: index == 0
                      ? context.sheet.ink
                      : context.sheet.fineRule,
                  width: index == 0 ? .9 : .55,
                ),
              ),
            ),
            child: row,
          ),
      ],
    ),
  );
}

/// What a parts-list row's state is reporting, so the style can colour it.
enum PartTone { plain, lit, alarmLit, warning }

/// One row of a drawing's parts list.
class DraftingPartRow extends StatelessWidget {
  const DraftingPartRow({
    super.key,
    required this.number,
    required this.name,
    required this.state,
    required this.symbol,
    this.tone = PartTone.plain,
    this.status,
  }) : header = false;

  const DraftingPartRow.header({super.key})
    : number = 'NO.',
      name = 'PART',
      state = 'STATE',
      symbol = null,
      status = null,
      tone = PartTone.plain,
      header = true;

  final String number;
  final String name;
  final String state;
  final PartTone tone;
  final Widget? symbol;
  final String? status;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final sheet = context.sheet;
    final size = header ? 8.0 : 10.0;
    final color = header ? sheet.faint : sheet.ink;
    final tracking = sheet == SheetStyle.light ? .25 : (header ? .76 : .62);
    final stateColor = header
        ? sheet.faint
        : switch (tone) {
            PartTone.plain => sheet.ink,
            PartTone.lit => sheet.beam,
            PartTone.alarmLit => sheet.alarmBeam,
            PartTone.warning => sheet.stamp,
          };
    final stateText = Text(
      state,
      textAlign: TextAlign.right,
      style: draftingLettering(size, color: stateColor, spacing: tracking),
    );
    final status = this.status;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: header ? 2 : 0),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            SizedBox(
              width: 21,
              child: Text(
                number,
                style: draftingLettering(size, color: color, spacing: tracking),
              ),
            ),
            SizedBox(width: 24, height: header ? 12 : 20, child: symbol),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: draftingLettering(size, color: color, spacing: tracking),
              ),
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * .55),
              child: status == null
                  ? stateText
                  : Tooltip(message: status, child: stateText),
            ),
          ],
        ),
      ),
    );
  }
}
