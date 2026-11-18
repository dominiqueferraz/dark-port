import 'package:flutter/material.dart';

import 'drafting_grid.dart';
import 'drafting_theme.dart';
import 'optical_bay.dart';
import 'part_symbols.dart';
import 'sheet_style.dart';
import 'signal_board.dart';
import 'signal_component.dart';

void showPartGuide(BuildContext context, {required bool wiredFirst}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final sheet = context.sheet;
      return AlertDialog(
        backgroundColor: sheet.paper,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: sheet.ink, width: 1.6),
        ),
        scrollable: true,
        title: Text(
          'Parts guide',
          style: draftingLettering(16, color: sheet.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wiredFirst) ..._wiredParts(context),
            ..._opticalParts(context),
            if (!wiredFirst) ..._wiredParts(context),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: draftingLettering(12, color: sheet.ink),
            ),
          ),
        ],
      );
    },
  );
}

Widget _heading(BuildContext context, String title) => Padding(
  padding: const EdgeInsets.only(top: 8, bottom: 6),
  child: Text(
    title,
    style: draftingLettering(10, color: context.sheet.faint, spacing: 1.6),
  ),
);

List<Widget> _opticalParts(BuildContext context) => [
  _heading(context, 'OPTICAL'),
  const _GuidePart(
    name: 'Laser source',
    description: 'Sends a continuous beam in its marked direction.',
    symbol: OpticalPartSymbol.source(),
  ),
  const _GuidePart(
    name: 'Mirror',
    description: 'Turns a beam 90°. Tap a loose mirror to turn it and drag it to move it.',
    symbol: OpticalPartSymbol.optic(OpticKind.mirror),
  ),
  const _GuidePart(
    name: 'Beam splitter',
    description: 'Passes half the incoming light straight through and turns the other half 90°.',
    symbol: OpticalPartSymbol.optic(OpticKind.splitter),
  ),
  const _GuidePart(
    name: 'Latch',
    description:
        'Receives light at the wall. Check its target in the parts list.',
    symbol: OpticalPartSymbol.receiver(lit: true),
  ),
  const _GuidePart(
    name: 'Optical alarm',
    description: 'Keep this receiver lit through every move. Losing its light trips the alarm.',
    symbol: OpticalPartSymbol.receiver(lit: true, alarm: true),
  ),
  const _GuidePart(
    name: 'Bolted mount',
    description: 'Marks a fixed part. It stays in its starting position and orientation.',
    symbol: OpticalPartSymbol.optic(OpticKind.mirror, fixed: true),
  ),
  const _GuidePart(
    name: 'Baffle',
    description: 'A hatched barrier stops any beam that reaches it.',
    symbol: _BaffleSymbol(),
  ),
];

List<Widget> _wiredParts(BuildContext context) => [
  _heading(context, 'WIRED'),
  _wiredPart(
    'Transmitter',
    SignalDeviceKind.transmitter,
    'Supplies signal units. Tap its output and then an input to attach a cable.',
  ),
  for (final splitter in SplitterType.values)
    _wiredPart(
      splitter.label,
      SignalDeviceKind.splitter,
      'Divides the incoming signal evenly between its ${splitter.outputs} outputs.',
      splitter: splitter,
    ),
  _wiredPart(
    'Attenuator',
    SignalDeviceKind.attenuator,
    'Reduces the signal by the selected number of units. Select the part to adjust its loss.',
  ),
  _wiredPart(
    'Receiver',
    SignalDeviceKind.receiver,
    'Accepts a signal in its target band. Some receivers also require a specific source.',
  ),
  _wiredPart(
    'Alarm blocker',
    SignalDeviceKind.receiver,
    'Combines two inputs. Keep its total within the target band while you rewire.',
    dualInput: true,
  ),
  _wiredPart(
    'Broadcaster',
    SignalDeviceKind.broadcaster,
    'Sends its wired input over the air to antennas within reach.',
  ),
  _wiredPart(
    'Antenna',
    SignalDeviceKind.antenna,
    'Receives radio signals on its channel. Walls can block the path.',
    fixed: true,
  ),
  _wiredPart(
    'Fixed component',
    SignalDeviceKind.transmitter,
    'Marks a bolted part. Loose wired parts can be dragged or flipped with a long press.',
    fixed: true,
  ),
];

Widget _wiredPart(
  String name,
  SignalDeviceKind kind,
  String description, {
  SplitterType? splitter,
  bool dualInput = false,
  bool fixed = false,
}) => _GuidePart(
  name: name,
  description: description,
  symbol: SignalComponent(
    device: SignalDevice(
      '',
      name,
      kind,
      const SignalPoint(0, 0),
      splitter: splitter,
      dualInput: dualInput,
      fixed: fixed,
    ),
  ),
);

class _GuidePart extends StatelessWidget {
  const _GuidePart({
    required this.name,
    required this.description,
    required this.symbol,
  });

  final String name;
  final String description;
  final Widget symbol;

  @override
  Widget build(BuildContext context) {
    final ink = context.sheet.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ink.withValues(alpha: .5), width: .7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            SizedBox.square(dimension: 40, child: symbol),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    name,
                    style: draftingLettering(12, color: ink, spacing: .5),
                  ),
                  Text(
                    description,
                    style: draftingLettering(11, color: ink, spacing: .2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaffleSymbol extends StatelessWidget {
  const _BaffleSymbol();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BafflePainter(context.sheet));
}

class _BafflePainter extends CustomPainter {
  const _BafflePainter(this.sheet);

  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) => paintHatchedBarrier(
    canvas,
    Rect.fromCenter(center: size.center(Offset.zero), width: 29, height: 10),
    sheet,
  );

  @override
  bool shouldRepaint(_BafflePainter oldDelegate) => sheet != oldDelegate.sheet;
}
