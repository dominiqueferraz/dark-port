import 'package:flutter/material.dart';

import 'drafting_grid.dart';
import 'drafting_theme.dart';
import 'lead_stock.dart';
import 'optical_bay.dart';
import 'part_symbols.dart';
import 'sheet_style.dart';
import 'signal_board.dart';
import 'signal_component.dart';

enum _PartCategory {
  optical('Optical'),
  wired('Wired'),
  radio('Radio'),
  cables('Cables');

  const _PartCategory(this.label);

  final String label;
}

enum GuidePart {
  laser(
    _PartCategory.optical,
    'Laser source',
    'Sends a continuous beam in its marked direction.',
  ),
  mirror(
    _PartCategory.optical,
    'Mirror',
    'Reflects light across its marked face. An axis-aligned beam turns 90°.',
  ),
  beamSplitter(
    _PartCategory.optical,
    'Beam splitter',
    'Sends half the light straight through and turns the other half 90°.',
  ),
  lightReceiver(
    _PartCategory.optical,
    'Light receiver',
    'Reads light from its marked approach. Check the required reading beside its name.',
  ),
  opticalAlarm(
    _PartCategory.optical,
    'Optical alarm',
    'Keep it lit through every move. Losing its light trips the alarm.',
  ),
  baffle(_PartCategory.optical, 'Baffle', 'Stops any beam that reaches it.'),
  opticalConverter(
    _PartCategory.radio,
    'Optical-to-radio converter',
    'Reads light at its aperture and sends that strength in its marked radio direction. Some inputs require a particular laser or strength.',
  ),
  mesh(_PartCategory.radio, 'Mesh wall', 'Stops light and lets radio pass.'),
  transmitter(
    _PartCategory.wired,
    'Transmitter',
    'Supplies signal units to its output.',
  ),
  twoWay(
    _PartCategory.wired,
    '2-way splitter',
    'Sends half the incoming strength to each output.',
  ),
  threeWay(
    _PartCategory.wired,
    '3-way splitter',
    'Sends a third of the incoming strength to each output.',
  ),
  fourWay(
    _PartCategory.wired,
    '4-way splitter',
    'Sends a quarter of the incoming strength to each output.',
  ),
  attenuator(
    _PartCategory.wired,
    'Attenuator',
    'Lowers the signal by the selected amount. Tap it to adjust its loss.',
  ),
  relay(
    _PartCategory.wired,
    'Relay',
    'Starts a new cable leg with its own reach and passes through the same signal.',
  ),
  receiver(
    _PartCategory.wired,
    'Receiver',
    'Accepts a signal in its target band. Some receivers also require a specific source.',
  ),
  alarmBlocker(
    _PartCategory.wired,
    'Alarm blocker',
    'Combines two inputs. Keep their total within the target band while you rewire.',
  ),
  broadcaster(
    _PartCategory.radio,
    'Broadcaster',
    'Takes a signal through a cable and broadcasts it as radio on the same channel.',
  ),
  antenna(
    _PartCategory.radio,
    'Antenna',
    'Receives radio on its channel from in-range broadcasters when concrete does not block the path. Check its target to see whether it should receive a signal or stay quiet.',
  ),
  concrete(
    _PartCategory.radio,
    'Concrete wall',
    'Blocks radio even inside coverage. A marked feedthrough can carry a matching cable.',
  ),
  patch(
    _PartCategory.cables,
    'Patch lead',
    'Connects ordinary sockets within the output’s reach.',
  ),
  shielded(
    _PartCategory.cables,
    'Shielded lead',
    'Crosses marked interference and matching feedthroughs. Reaches up to four units within the output’s range.',
  ),
  trunk(
    _PartCategory.cables,
    'Trunk lead',
    'Follows a straight marked run and crosses walls at matching feedthroughs. Reaches up to six units within the output’s range.',
  ),
  interference(
    _PartCategory.cables,
    'Interference zone',
    'Requires a shielded lead wherever a cable corridor crosses the marked area.',
  ),
  feedthrough(
    _PartCategory.cables,
    'Feedthrough',
    'Lets the matching type of cable cross a wall. The wall still blocks radio.',
  );

  const GuidePart(this._category, this.label, this.description);

  final _PartCategory _category;
  final String label;
  final String description;
}

Set<GuidePart> opticalGuideParts(OpticalLevel board) => {
  GuidePart.laser,
  for (final optic in board.initial)
    switch (optic.kind) {
      OpticKind.mirror => GuidePart.mirror,
      OpticKind.splitter => GuidePart.beamSplitter,
      OpticKind.converter => GuidePart.opticalConverter,
    },
  if (board.receivers.length > board.alarms.length) GuidePart.lightReceiver,
  if (board.alarms.isNotEmpty) GuidePart.opticalAlarm,
  if (board.blocks.isNotEmpty) GuidePart.baffle,
  if (board.antennas.isNotEmpty) GuidePart.antenna,
  if (board.barriers.any((wall) => wall.material == BarrierMaterial.mesh))
    GuidePart.mesh,
  if (board.barriers.any((wall) => wall.material == BarrierMaterial.concrete))
    GuidePart.concrete,
};

Set<GuidePart> signalGuideParts(SignalBoard board) => {
  for (final device in board.devices)
    switch (device.kind) {
      SignalDeviceKind.transmitter => GuidePart.transmitter,
      SignalDeviceKind.splitter => switch (device.splitter!) {
        SplitterType.twoWay => GuidePart.twoWay,
        SplitterType.threeWay => GuidePart.threeWay,
        SplitterType.fourWay => GuidePart.fourWay,
      },
      SignalDeviceKind.attenuator => GuidePart.attenuator,
      SignalDeviceKind.relay => GuidePart.relay,
      SignalDeviceKind.receiver =>
        device == board.alarm?.blocker
            ? GuidePart.alarmBlocker
            : GuidePart.receiver,
      SignalDeviceKind.broadcaster => GuidePart.broadcaster,
      SignalDeviceKind.antenna => GuidePart.antenna,
    },
  if (board.radioWalls.isNotEmpty) GuidePart.concrete,
  if (board.patchLeadStock != 0) GuidePart.patch,
  if (board.shieldedLeadStock > 0) GuidePart.shielded,
  if (board.trunkLeadStock > 0) GuidePart.trunk,
  if (board.interference != null) GuidePart.interference,
  if (board.feedthroughs.isNotEmpty) GuidePart.feedthrough,
};

void showPartGuide(
  BuildContext context, {
  required Set<GuidePart> puzzleParts,
  required Set<GuidePart> revealedParts,
}) {
  final known = {...revealedParts, ...puzzleParts};
  showDialog<void>(
    context: context,
    builder: (context) {
      final sheet = context.sheet;
      final tabs = [
        ('This puzzle', _partsPage('puzzle', puzzleParts.contains)),
        for (final category in _PartCategory.values)
          if (known.any((part) => part._category == category))
            (
              category.label,
              _partsPage(
                category.name,
                (part) => part._category == category && known.contains(part),
              ),
            ),
        ('Controls', _controlsPage(known)),
      ];
      return DefaultTabController(
        length: tabs.length,
        child: Dialog(
          backgroundColor: sheet.paper,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: sheet.ink, width: 1.6),
          ),
          child: SizedBox(
            width: 660,
            height: 430,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Parts guide',
                          style: draftingLettering(16, color: sheet.ink),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: draftingLettering(12, color: sheet.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  labelStyle: draftingLettering(13, spacing: .35),
                  labelColor: sheet.ink,
                  unselectedLabelColor: sheet.faint,
                  indicatorColor: sheet.ink,
                  dividerColor: sheet.fineRule,
                  tabs: [for (final (label, _) in tabs) Tab(text: label)],
                ),
                Expanded(
                  child: TabBarView(
                    children: [for (final (_, page) in tabs) page],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _partsPage(String id, bool Function(GuidePart) includes) => ListView(
  key: PageStorageKey(id),
  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
  children: [
    for (final part in GuidePart.values.where(includes))
      _GuidePart(
        name: part.label,
        description: part.description,
        symbol: _symbol(part),
      ),
  ],
);

Widget _controlsPage(Set<GuidePart> known) => ListView(
  key: const PageStorageKey('controls'),
  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
  children: [
    const _ControlHelp(
      'Placement',
      'Drag a loose part to a marked spot and release it. Bolts mark parts that stay fixed.',
    ),
    if (known.contains(GuidePart.mirror) ||
        known.contains(GuidePart.beamSplitter))
      const _ControlHelp(
        'Rotation',
        'Tap a loose optic to turn it a quarter turn.',
      ),
    if (known.contains(GuidePart.patch))
      const _ControlHelp(
        'Wiring',
        'Tap an output, then an input. If a route preview appears, tap the input again to install the cable. Select a connected part to disconnect a cable. Hold a flippable part to mirror its sockets.',
      ),
    const _ControlHelp(
      'Readings',
      'Compare the current reading with the target. Open Hint for the full goal of the puzzle.',
    ),
    const _ControlHelp(
      'Undo and reset',
      'Undo and Redo step through edits. Reset restores the starting arrangement.',
    ),
  ],
);

class _ControlHelp extends StatelessWidget {
  const _ControlHelp(this.title, this.description);

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        Text(title, style: draftingLettering(13, spacing: .4)),
        Text(description, style: draftingLettering(12, spacing: .2)),
      ],
    ),
  );
}

Widget _symbol(GuidePart part) => switch (part) {
  GuidePart.laser => const OpticalPartSymbol.source(),
  GuidePart.mirror => const OpticalPartSymbol.optic(OpticKind.mirror),
  GuidePart.beamSplitter => const OpticalPartSymbol.optic(OpticKind.splitter),
  GuidePart.lightReceiver => const OpticalPartSymbol.receiver(lit: true),
  GuidePart.opticalAlarm => const OpticalPartSymbol.receiver(
    lit: true,
    alarm: true,
  ),
  GuidePart.opticalConverter => const ConverterSymbol(),
  GuidePart.baffle ||
  GuidePart.mesh ||
  GuidePart.concrete ||
  GuidePart.interference ||
  GuidePart.feedthrough => _BarrierSymbol(part),
  GuidePart.patch => const LeadSymbol(type: LeadType.patch),
  GuidePart.shielded => const LeadSymbol(type: LeadType.shielded),
  GuidePart.trunk => const LeadSymbol(type: LeadType.trunk),
  GuidePart.transmitter => _wiredSymbol(SignalDeviceKind.transmitter),
  GuidePart.twoWay => _wiredSymbol(
    SignalDeviceKind.splitter,
    splitter: SplitterType.twoWay,
  ),
  GuidePart.threeWay => _wiredSymbol(
    SignalDeviceKind.splitter,
    splitter: SplitterType.threeWay,
  ),
  GuidePart.fourWay => _wiredSymbol(
    SignalDeviceKind.splitter,
    splitter: SplitterType.fourWay,
  ),
  GuidePart.attenuator => _wiredSymbol(SignalDeviceKind.attenuator),
  GuidePart.relay => _wiredSymbol(SignalDeviceKind.relay),
  GuidePart.receiver => _wiredSymbol(SignalDeviceKind.receiver),
  GuidePart.alarmBlocker => _wiredSymbol(
    SignalDeviceKind.receiver,
    dualInput: true,
  ),
  GuidePart.broadcaster => _wiredSymbol(SignalDeviceKind.broadcaster),
  GuidePart.antenna => _wiredSymbol(SignalDeviceKind.antenna, fixed: true),
};

Widget _wiredSymbol(
  SignalDeviceKind kind, {
  SplitterType? splitter,
  bool dualInput = false,
  bool fixed = false,
}) => SignalComponent(
  device: SignalDevice(
    '',
    '',
    kind,
    const SignalPoint(0, 0),
    splitter: splitter,
    dualInput: dualInput,
    fixed: fixed,
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

class _BarrierSymbol extends StatelessWidget {
  const _BarrierSymbol(this.kind);

  final GuidePart kind;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BarrierPainter(kind, context.sheet));
}

class _BarrierPainter extends CustomPainter {
  const _BarrierPainter(this.kind, this.sheet);

  final GuidePart kind;
  final SheetStyle sheet;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shape = switch (kind) {
      GuidePart.baffle => const Size(29, 10),
      GuidePart.interference => const Size(20, 20),
      _ => const Size(6, 29),
    };
    final bounds = Rect.fromCenter(
      center: center,
      width: shape.width,
      height: shape.height,
    );
    if (kind == GuidePart.mesh) {
      paintMeshBarrier(canvas, bounds, sheet);
    } else {
      paintHatchedBarrier(canvas, bounds, sheet);
    }
    if (kind == GuidePart.feedthrough) {
      final jack = Rect.fromCenter(center: center, width: 11, height: 11);
      canvas.drawRect(jack, Paint()..color = sheet.paper);
      canvas.drawRect(
        jack,
        Paint()
          ..color = sheet.ink
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_BarrierPainter oldDelegate) =>
      kind != oldDelegate.kind || sheet != oldDelegate.sheet;
}
