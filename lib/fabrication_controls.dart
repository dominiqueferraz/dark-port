import 'package:flutter/material.dart';

import 'drafting_theme.dart';
import 'sheet_style.dart';

class FabricationControls extends StatelessWidget {
  const FabricationControls({
    super.key,
    required this.empty,
    required this.onWorkbench,
    required this.onInsert,
    this.label,
  });

  final bool empty;
  final String? label;
  final VoidCallback? onWorkbench;
  final VoidCallback? onInsert;

  @override
  Widget build(BuildContext context) {
    Widget action(String label, IconData icon, VoidCallback? onPressed) =>
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label, style: draftingLettering(12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.sheet.ink,
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            shape: const RoundedRectangleBorder(),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 3,
      children: [
        if (empty)
          Text(
            label == null
                ? 'Fabrication required'
                : '$label · Fabrication required',
            style: draftingLettering(11, color: context.sheet.stamp),
          ),
        Row(
          spacing: 6,
          children: [
            Expanded(
              child: action('Workbench', Icons.build_outlined, onWorkbench),
            ),
            Expanded(
              child: action(
                empty ? 'Insert part' : 'Replace part',
                Icons.extension_outlined,
                onInsert,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
