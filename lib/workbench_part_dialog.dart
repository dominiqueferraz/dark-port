import 'package:flutter/material.dart';

import 'drafting_controls.dart';
import 'part_symbols.dart';
import 'sheet_style.dart';
import 'workbench_part_mark.dart';

class WorkbenchPartDialog extends StatefulWidget {
  const WorkbenchPartDialog({
    super.key,
    required this.mark,
    required this.defaultName,
  });

  final WorkbenchPartMark mark;
  final String defaultName;

  @override
  State<WorkbenchPartDialog> createState() => _WorkbenchPartDialogState();
}

class _WorkbenchPartDialogState extends State<WorkbenchPartDialog> {
  late final _name = TextEditingController(text: widget.mark.name);
  late WorkbenchIcon? _icon = widget.mark.icon;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() =>
      Navigator.pop(context, (name: _name.text.trim(), icon: _icon));

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: context.sheet.paper,
    title: const Text('Customize part'),
    scrollable: true,
    content: SizedBox(
      width: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Part name',
              hintText: widget.defaultName,
              counterText: '',
            ),
            maxLength: 32,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final icon in [null, ...WorkbenchIcon.values])
                SizedBox.fromSize(
                  size: consoleButtonSize,
                  child: Semantics(
                    selected: _icon == icon,
                    child: consoleButton(
                      tooltip: icon?.label ?? 'Default icon',
                      emphasized: _icon == icon,
                      onPressed: () => setState(() => _icon = icon),
                      icon: Icon(icon?.symbol ?? Icons.circle_outlined),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
        label: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save part'),
      ),
    ],
  );
}
