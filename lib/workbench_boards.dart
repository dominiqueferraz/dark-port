import 'dart:math' as math;

import 'optical_bay.dart';
import 'tutorial.dart';

const _floor = math.Rectangle<double>(-5.25, -4.2, 10.5, 7.35);
const _laser = FloorPoint(0, -3.5);
const _laserFoot = FloorPoint(0, -3.95);
const _center = FloorPoint(0, 0);
const _lowerMount = FloorPoint(0, -1.05);
const workbenchSocket = Optic('W1', OpticKind.workbenchSplitter, _center);

const workbenchTestBoard = OpticalLevel(
  title: 'Test bench',
  laser: _laser,
  laserFoot: _laserFoot,
  direction: BeamDirection.north,
  receivers: [],
  goal: {},
  initial: [workbenchSocket],
  floor: _floor,
  mounts: {
    'W1': [(position: _center, intersection: true)],
  },
);

OpticalLevel aimedWorkbenchBench(
  OpticalLevel bench,
  BeamDirection travel, {
  List<math.Rectangle<double>> blocks = const [],
}) {
  if (travel == bench.direction && blocks.isEmpty) return bench;
  return OpticalLevel(
    title: bench.title,
    laser: travel == bench.direction
        ? bench.laser
        : FloorPoint(-travel.x * 2.55, -travel.y * 2.55),
    laserFoot: travel == bench.direction
        ? bench.laserFoot
        : FloorPoint(-travel.x * 2.95, -travel.y * 2.95),
    direction: travel,
    receivers: bench.receivers,
    goal: bench.goal,
    initial: bench.initial,
    floor: bench.floor,
    mounts: bench.mounts,
    blocks: [...bench.blocks, ...blocks],
  );
}

const _ahead = OpticalReceiver(
  'Straight latch',
  FloorPoint(0, 3.15),
  BeamDirection.north,
  requiredPower: 50,
);
const _left = OpticalReceiver(
  'Left latch',
  FloorPoint(-3.15, 3.15),
  BeamDirection.northWest,
  requiredPower: 50,
);
const _right = OpticalReceiver(
  'Right latch',
  FloorPoint(3.15, 3.15),
  BeamDirection.northEast,
  requiredPower: 50,
);

OpticalLesson _sheet(
  String slug, {
  required String title,
  required String objective,
  required String goal,
  required List<String> notes,
  required List<OpticalReceiver> receivers,
  List<Optic> parts = const [],
  Map<String, List<GridSpot>> extraMounts = const {},
  List<math.Rectangle<double>> blocks = const [],
  bool twoMounts = false,
}) => OpticalLesson(
  'endless.$slug',
  OpticalLevel(
    title: title,
    laser: _laser,
    laserFoot: _laserFoot,
    direction: BeamDirection.north,
    receivers: receivers,
    goal: Set.unmodifiable(Iterable<int>.generate(receivers.length)),
    initial: [
      twoMounts ? workbenchSocket.at(_lowerMount) : workbenchSocket,
      ...parts,
    ],
    floor: _floor,
    blocks: blocks,
    mounts: {
      'W1': [
        (position: _center, intersection: true),
        if (twoMounts) (position: _lowerMount, intersection: true),
      ],
      ...extraMounts,
    },
  ),
  objective: objective,
  goal: goal,
  notes: [
    'Open Workbench to test a two-port splitter, save its blueprint and fit it to the socket.',
    ...notes,
  ],
);

final workbenchDiagonalLatch = _sheet(
  'diagonal-latch',
  title: 'Diagonal Latch',
  objective: 'Light both latches with one custom splitter.',
  goal: 'Deliver 50 u to the straight latch and 50 u to the diagonal latch.',
  notes: [
    'Angles are measured from the incoming beam. Positive angles turn clockwise.',
  ],
  receivers: [_ahead, _right],
);

final workbenchTwinLatches = _sheet(
  'twin-latches',
  title: 'Twin Latches',
  objective: 'Light both diagonal latches.',
  goal: 'Deliver 50 u to each of the two diagonal latches.',
  notes: [
    'Drag the splitter to change where both branches leave the incoming beam.',
  ],
  receivers: [_left, _right],
  twoMounts: true,
  blocks: [math.Rectangle<double>(-.35, 1.2, .7, .35)],
);

final workbenchOffsetLatch = _sheet(
  'offset-latch',
  title: 'Offset Latch',
  objective: 'Light the diagonal and side latches.',
  goal: 'Deliver 50 u to the left latch and 50 u to the side latch.',
  notes: [
    'You can choose a different angle for each port. Tap the installed splitter to mirror both angles.',
  ],
  receivers: [
    _left,
    OpticalReceiver(
      'Side latch',
      FloorPoint(5.25, 0),
      BeamDirection.east,
      requiredPower: 50,
    ),
  ],
);

final workbenchReturnFold = _sheet(
  'return-fold',
  title: 'Return Fold',
  objective: 'Light both latches beyond the screen.',
  goal: 'Deliver 50 u to the left latch and 50 u to the upper latch.',
  notes: [
    'A stock mirror can turn one branch without changing its power. Find the mount that leaves its return path clear.',
  ],
  receivers: [
    _left,
    OpticalReceiver(
      'Upper latch',
      FloorPoint(2.1, 3.15),
      BeamDirection.north,
      requiredPower: 50,
    ),
  ],
  parts: [Optic('M1', OpticKind.mirror, FloorPoint(3.15, 0), turned: true)],
  extraMounts: {
    'M1': [
      (position: FloorPoint(2.1, 0), intersection: true),
      (position: FloorPoint(3.15, 0), intersection: true),
    ],
  },
  blocks: [math.Rectangle<double>(2.83, 1.1, .64, .45)],
);

final workbenchSplitTheSplit = _sheet(
  'split-the-split',
  title: 'Split the Split',
  objective: 'Light all three latches at their marked power.',
  goal: 'Deliver 50 u to the diagonal latch and 25 u to each of the other two latches.',
  notes: [
    'Splitting a branch again halves the strength arriving at the second splitter.',
  ],
  receivers: [
    OpticalReceiver(
      'Straight latch',
      FloorPoint(0, 3.15),
      BeamDirection.north,
      requiredPower: 25,
    ),
    OpticalReceiver(
      'Side latch',
      FloorPoint(5.25, 1.05),
      BeamDirection.east,
      requiredPower: 25,
    ),
    _right,
  ],
  parts: [Optic('S1', OpticKind.splitter, FloorPoint(0, 2.1))],
  extraMounts: {
    'S1': [
      (position: FloorPoint(0, 1.05), intersection: true),
      (position: FloorPoint(0, 2.1), intersection: true),
    ],
  },
  blocks: [math.Rectangle<double>(2.8, 1.95, .55, .3)],
);

final workbenchSplitAndDim = _sheet(
  'split-and-dim',
  title: 'Split and Dim',
  objective: 'Match the two latch power ratings.',
  goal: 'Deliver 50 u to the straight latch and 25 u to the diagonal latch.',
  notes: [
    'The splitter core gives each port half the light. Clip a half-power filter onto one port to halve that branch again.',
  ],
  receivers: [
    _ahead,
    OpticalReceiver(
      'Low-power latch',
      FloorPoint(3.15, 3.15),
      BeamDirection.northEast,
      requiredPower: 25,
    ),
  ],
);
