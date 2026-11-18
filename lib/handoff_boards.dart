import 'dart:math' as math;

import 'optical_bay.dart';
import 'placement_nodes.dart';
import 'signal_board.dart';
import 'tutorial.dart';

const _north = BeamDirection.north;
const _east = BeamDirection.east;
const _south = BeamDirection.south;
const _west = BeamDirection.west;
const _sheet = math.Rectangle<double>(0, 0, 13, 9);

List<PlacementNode> _mounts(List<FloorPoint> points) => [
  for (final point in points) (position: point, intersection: true),
];

final bothFacesLesson = OpticalLesson(
  'endless.both-faces',
  OpticalLevel(
    title: 'Both Faces',
    floor: _sheet,
    tileSize: 1,
    laser: const FloorPoint(1.15, 4.27),
    laserFoot: const FloorPoint(.7, 4.27),
    direction: _east,
    sourceLabel: 'L',
    additionalSources: const [
      OpticalSource(
        'R',
        FloorPoint(11.85, 4.10),
        FloorPoint(12.3, 4.10),
        _west,
      ),
    ],
    receivers: const [
      OpticalReceiver('North', FloorPoint(5.77, 8), _north, requiredPower: 100),
      OpticalReceiver('South', FloorPoint(5.60, 1), _south, requiredPower: 100),
    ],
    goal: const {0, 1},
    initial: const [Optic('M1', OpticKind.mirror, FloorPoint(4, 4))],
    mounts: {
      'M1': _mounts(const [
        FloorPoint(4, 4),
        FloorPoint(5.5, 4),
        FloorPoint(6, 4.5),
      ]),
    },
  ),
  objective: 'Light both sensors with one mirror.',
  goal: 'Deliver 100 u to North and 100 u to South.',
  notes: const [
    'One mirror can catch beams on both sides. Turning it changes both exits together.',
    'One mount catches only the beam going to North.',
  ],
);

final twoBranchesTwoBendsLesson = OpticalLesson(
  'endless.two-branches-two-bends',
  OpticalLevel(
    title: 'Two Branches, Two Bends',
    floor: _sheet,
    tileSize: 1,
    laser: const FloorPoint(1.15, 2),
    laserFoot: const FloorPoint(.7, 2),
    direction: _east,
    receivers: const [
      OpticalReceiver('North', FloorPoint(9, 8), _north, requiredPower: 50),
      OpticalReceiver('East', FloorPoint(11.5, 6), _east, requiredPower: 50),
    ],
    goal: const {0, 1},
    initial: const [
      Optic('S1', OpticKind.splitter, FloorPoint(3, 2), turned: true),
      Optic('M1', OpticKind.mirror, FloorPoint(3, 4)),
      Optic('M2', OpticKind.mirror, FloorPoint(7, 2)),
    ],
    blocks: const [math.Rectangle<double>(4, 3, 4, 2)],
    mounts: {
      'S1': _mounts(const [FloorPoint(3, 2)]),
      'M1': _mounts(const [FloorPoint(3, 4), FloorPoint(9, 2)]),
      'M2': _mounts(const [FloorPoint(7, 2), FloorPoint(3, 6)]),
    },
  ),
  objective: 'Carry both halves around the baffle.',
  goal: 'Deliver 50 u to North and 50 u to East.',
  notes: const [
    'The two mirrors turn one branch each. A turn made too early hits the baffle.',
    'Check the marked approach on each sensor.',
  ],
);

Optic _fixedConverter(
  String id,
  FloorPoint position,
  BeamDirection incoming,
  BeamDirection outgoing, {
  int channel = 12,
  double reach = 4,
  double? power,
  String? source,
}) => Optic(
  id,
  OpticKind.converter,
  position,
  fixed: true,
  converter: OpticalConverter(
    channel: channel,
    reach: reach,
    power: power,
    requiredSource: source,
    lanes: {position: (incoming: incoming, outgoing: outgoing)},
  ),
);

OpticalLevel _firstConversion(
  String title, {
  List<OpticalBarrier> barriers = const [],
}) => OpticalLevel(
  title: title,
  floor: _sheet,
  tileSize: 1,
  laser: const FloorPoint(1.15, 5),
  laserFoot: const FloorPoint(.7, 5),
  direction: _east,
  receivers: const [
    OpticalReceiver('Inspection', FloorPoint(6, 5), _east, requiredPower: 50),
  ],
  goal: const {0},
  initial: [
    const Optic('S1', OpticKind.splitter, FloorPoint(3, 5), turned: true),
    const Optic('M1', OpticKind.mirror, FloorPoint(3, 3)),
    _fixedConverter('C1', const FloorPoint(5, 3), _east, _east, power: 50),
  ],
  mounts: {
    'S1': _mounts(const [FloorPoint(3, 5)]),
    'M1': _mounts(const [FloorPoint(3, 3)]),
  },
  barriers: barriers,
  antennas: const [
    OpticalAntenna('Remote', FloorPoint(9, 3), channel: 12, minimum: 30),
  ],
);

final firstConversionLesson = OpticalLesson(
  'endless.first-conversion',
  _firstConversion('First Conversion'),
  objective: 'Light Inspection and bring Remote online.',
  goal: 'Deliver 50 u to Inspection and at least 30 u to Remote on channel 12.',
  notes: const [
    'The converter uses its incoming light to transmit radio on channel 12.',
    'The four-step hop loses 20 u. Check the optical input and radio reading separately.',
  ],
);

const _eastLane = FloorPoint(10, 5);
const _southLane = FloorPoint(7, 1);
const _westLane = FloorPoint(2, 5);

OpticalLevel _launchLanes({required bool longLane}) {
  final concreteLane = longLane ? _eastLane : const FloorPoint(3, 5);
  final lanes = {
    concreteLane: (incoming: _north, outgoing: longLane ? _west : _east),
    _southLane: (incoming: _south, outgoing: _north),
    if (longLane) _westLane: (incoming: _north, outgoing: _east),
  };
  return OpticalLevel(
    title: longLane ? 'Around the Shield' : 'Mesh Window',
    floor: _sheet,
    tileSize: 1,
    laser: const FloorPoint(1, 1.15),
    laserFoot: const FloorPoint(1, .7),
    direction: _north,
    receivers: const [
      OpticalReceiver('Local', FloorPoint(1, 8), _north, requiredPower: 50),
    ],
    goal: const {0},
    initial: [
      const Optic('S1', OpticKind.splitter, FloorPoint(1, 3)),
      Optic('M1', OpticKind.mirror, FloorPoint(concreteLane.x, 3)),
      Optic(
        'C1',
        OpticKind.converter,
        concreteLane,
        converter: OpticalConverter(
          channel: 12,
          reach: longLane ? 5 : 4,
          power: 50,
          lanes: lanes,
        ),
      ),
    ],
    mounts: {
      'S1': _mounts(const [FloorPoint(1, 3)]),
      'M1': _mounts([for (final point in lanes.keys) FloorPoint(point.x, 3)]),
      'C1': _mounts(lanes.keys.toList()),
    },
    barriers: [
      (
        bounds: math.Rectangle<double>(longLane ? 8.4 : 4.8, 4.55, .25, .9),
        material: BarrierMaterial.concrete,
      ),
      (
        bounds: const math.Rectangle<double>(6.55, 3.85, .9, .25),
        material: BarrierMaterial.mesh,
      ),
    ],
    antennas: const [
      OpticalAntenna('Remote', FloorPoint(7, 5), channel: 12, minimum: 30),
    ],
  );
}

final meshWindowLesson = OpticalLesson(
  'endless.mesh-window',
  _launchLanes(longLane: false),
  objective: 'Bring Remote online through the mesh.',
  goal: 'Deliver 50 u to Local and at least 30 u to Remote.',
  notes: const [
    'Both walls stop light. Mesh passes radio, while concrete blocks it.',
    'Move the converter to the other launch mark. Move and turn the mirror to feed its marked input.',
  ],
);

final aroundTheShieldLesson = OpticalLesson(
  'endless.around-the-shield',
  _launchLanes(longLane: true),
  objective: 'Find a launch lane with enough radio power.',
  goal: 'Deliver 50 u to Local and at least 30 u to Remote.',
  notes: const [
    'All three launch marks are inside coverage. Check what arrives at Remote from each one.',
    'Move the converter and use the mirror to feed its light input.',
  ],
);

final splitTwiceLesson = OpticalLesson(
  'endless.split-twice',
  OpticalLevel(
    title: 'Split Twice',
    floor: _sheet,
    tileSize: 1,
    laser: const FloorPoint(1.15, 3),
    laserFoot: const FloorPoint(.7, 3),
    direction: _east,
    receivers: const [
      OpticalReceiver('North', FloorPoint(3, 8), _north, requiredPower: 25),
      OpticalReceiver('East', FloorPoint(10.5, 5), _east, requiredPower: 25),
    ],
    goal: const {0, 1},
    initial: [
      const Optic('S1', OpticKind.splitter, FloorPoint(3, 3)),
      const Optic('S2', OpticKind.splitter, FloorPoint(3, 5), turned: true),
      const Optic('M1', OpticKind.mirror, FloorPoint(8, 5), turned: true),
      _fixedConverter('C1', const FloorPoint(8, 1), _south, _east),
    ],
    mounts: {
      'S1': _mounts(const [FloorPoint(3, 3)]),
      'S2': _mounts(const [FloorPoint(3, 5)]),
      'M1': _mounts(const [FloorPoint(8, 5), FloorPoint(8, 3)]),
    },
    antennas: const [
      OpticalAntenna('Remote', FloorPoint(12, 1), channel: 12, minimum: 30),
    ],
  ),
  objective: 'Power both inspection sensors and Remote.',
  goal: 'Deliver 25 u to each sensor and at least 30 u to Remote.',
  notes: const [
    'Splitting a 50 u branch again gives two 25 u branches.',
    'Reserve enough power for the four-step radio hop.',
  ],
);

final crossedChannelsLesson = OpticalLesson(
  'endless.crossed-channels',
  OpticalLevel(
    title: 'Crossed Channels',
    floor: const math.Rectangle<double>(0, 0, 14, 9),
    tileSize: 1,
    laser: const FloorPoint(1.15, 5),
    laserFoot: const FloorPoint(.7, 5),
    direction: _east,
    receivers: const [],
    goal: const {},
    initial: [
      const Optic('S1', OpticKind.splitter, FloorPoint(3, 5)),
      const Optic('M1', OpticKind.mirror, FloorPoint(7, 5), turned: true),
      const Optic('M2', OpticKind.mirror, FloorPoint(3, 6)),
      _fixedConverter(
        'C9',
        const FloorPoint(8, 3),
        _south,
        _east,
        channel: 9,
        reach: 5,
        power: 50,
      ),
      _fixedConverter('C12', const FloorPoint(13, 7), _east, _south, power: 50),
    ],
    mounts: {
      'S1': _mounts(const [FloorPoint(3, 5)]),
      'M1': _mounts(const [FloorPoint(7, 5), FloorPoint(8, 5)]),
      'M2': _mounts(const [FloorPoint(3, 6), FloorPoint(3, 7)]),
    },
    barriers: const [
      (
        bounds: math.Rectangle<double>(6.55, 3.8, .9, .25),
        material: BarrierMaterial.concrete,
      ),
    ],
    antennas: const [
      OpticalAntenna('Antenna 9', FloorPoint(12, 3), channel: 9, minimum: 30),
      OpticalAntenna('Antenna 12', FloorPoint(13, 3), channel: 12, minimum: 30),
    ],
  ),
  objective: 'Bring both channel-matched antennas online.',
  goal: 'Deliver at least 30 u to each antenna on its marked channel.',
  notes: const [
    'An antenna reads its own channel. Channel 9 passes by the channel-12 antenna.',
    'Steer one branch into each converter and compare the readings.',
  ],
);

const _shielded = SignalPoint(4.76, 2.5);
const _trunk = SignalPoint(1.76, 3.5);
const _ordinary = SignalPoint(4.76, 3.5);
const _feed = SignalDevice(
  'feed',
  'Feed',
  SignalDeviceKind.transmitter,
  SignalPoint(.55, 1.35),
  strength: 120,
  cableRange: 8,
  fixed: true,
);
const _load = SignalDevice(
  'load',
  'Service load',
  SignalDeviceKind.receiver,
  SignalPoint(8.5, .9),
  minimumStrength: 60,
  maximumStrength: 60,
  fixed: true,
);
const _mast = SignalDevice(
  'broadcaster',
  'Service mast',
  SignalDeviceKind.broadcaster,
  SignalPoint(8.5, 3.5),
  radioRange: 6,
  fixed: true,
);
const _service = SignalDevice(
  'service',
  'Service antenna',
  SignalDeviceKind.antenna,
  SignalPoint(12.5, 3.5),
  minimumStrength: 40,
  fixed: true,
);
const _guard = SignalDevice(
  'guard',
  'Guard antenna',
  SignalDeviceKind.antenna,
  SignalPoint(11.5, 6.5),
  tripStrength: 35,
  fixed: true,
);
const _serviceMounts = [
  (position: _shielded, intersection: true),
  (position: _trunk, intersection: true),
  (position: _ordinary, intersection: true),
];

String? serviceSolutionAt(SignalPoint mount) => switch (mount) {
  _shielded => 'shielded-service',
  _trunk => 'trunk-service',
  _ordinary => 'ordinary-service',
  _ => null,
};

Iterable<CableCorridor> _serviceCorridors(SignalPoint mount) sync* {
  final supply = _feed.initialPosition + SignalBoard.outputPort(0);
  final input = mount + SignalBoard.inputPort(0);
  final loadBranch = mount + SignalBoard.outputPort(1);
  final load = _load.initialPosition + SignalBoard.inputPort(0);
  yield CableCorridor([
    supply,
    SignalPoint(input.x - .17, supply.y),
    SignalPoint(input.x - .17, input.y),
    input,
  ]);
  yield CableCorridor([loadBranch, SignalPoint(loadBranch.x, load.y), load]);
}

final serviceAndInspectionBoard = SignalBoard(
  size: 13,
  height: 7,
  placementNodes: _serviceMounts,
  devices: const [
    _feed,
    SignalDevice(
      'splitter',
      'Service splitter',
      SignalDeviceKind.splitter,
      _shielded,
      splitter: SplitterType.twoWay,
      cableRange: 9,
      mounts: _serviceMounts,
    ),
    _mast,
    _load,
    _service,
    _guard,
  ],
  goals: const [_load, _service, _guard],
  cableCorridors: [
    for (final mount in _serviceMounts) ..._serviceCorridors(mount.position),
    const CableCorridor([
      SignalPoint(5.13, 2.5),
      SignalPoint(7.5, 2.5),
      SignalPoint(7.5, 3.5),
      SignalPoint(8.13, 3.5),
    ]),
    const CableCorridor([
      SignalPoint(2.13, 3.5),
      SignalPoint(8.13, 3.5),
    ], trunk: true),
    const CableCorridor([SignalPoint(5.13, 3.5), SignalPoint(8.13, 3.5)]),
  ],
  radioWalls: const [RadioWall(4, 3.12, 3.88)],
  feedthroughs: {
    const SignalPoint(4, 3.5): const {LeadType.trunk},
  },
  interference: const math.Rectangle<double>(5.7, 2.3, 1.3, .4),
  patchLeadStock: 3,
  shieldedLeadStock: 1,
  trunkLeadStock: 1,
);

final serviceAndInspectionLesson = OpticalLesson(
  'endless.service-and-inspection',
  _firstConversion(
    'Service and Inspection',
    barriers: const [
      (
        bounds: math.Rectangle<double>(6.9, 2.55, .2, .9),
        material: BarrierMaterial.mesh,
      ),
    ],
  ),
  wiredBoard: serviceAndInspectionBoard,
  objective: 'Complete the service and inspection circuits.',
  goal:
      'Deliver 60 u to the load and at least 40 u to Service. Keep Guard below 35 u. '
      'Deliver 50 u to Inspection and at least 30 u to Remote.',
  notes: const [
    'Use the Wired and Optical views to work on both circuits. Both must satisfy their readings together.',
    'The splitter has three legal service corridors. Preview the cable and length before installing it.',
  ],
);

OpticalLevel _pairedHandoff({required bool split}) {
  final left = split ? const FloorPoint(2, 4) : const FloorPoint(1, 4);
  final right = split ? const FloorPoint(8, 4) : const FloorPoint(10, 4);
  return OpticalLevel(
    title: split ? 'Dual Handoff' : 'One Mirror, Two Windows',
    floor: const math.Rectangle<double>(-1, 0, 12, 8),
    tileSize: 1,
    laser: const FloorPoint(.55, 4),
    laserFoot: const FloorPoint(0, 4),
    direction: _east,
    sourceLabel: 'L',
    additionalSources: const [
      OpticalSource('R', FloorPoint(9.45, 4), FloorPoint(10, 4), _west),
    ],
    receivers: [
      if (split) ...[
        OpticalReceiver(
          'Local L',
          FloorPoint(left.x, 7),
          _north,
          requiredPower: 50,
        ),
        OpticalReceiver(
          'Local R',
          FloorPoint(right.x, 1),
          _south,
          requiredPower: 50,
        ),
      ],
    ],
    goal: split ? const {0, 1} : const {},
    initial: [
      if (split) ...[
        Optic('SL', OpticKind.splitter, left, turned: true),
        Optic('SR', OpticKind.splitter, right, turned: true),
      ],
      Optic(
        'M1',
        OpticKind.mirror,
        FloorPoint(split ? 4 : 5, 4),
        turned: !split,
      ),
      _fixedConverter(
        'CL',
        const FloorPoint(5, 6),
        _north,
        _east,
        source: 'L',
        power: split ? 50 : 100,
      ),
      _fixedConverter(
        'CR',
        const FloorPoint(5, 2),
        _south,
        _east,
        source: 'R',
        power: split ? 50 : 100,
      ),
    ],
    mounts: {
      if (split) ...{
        'SL': _mounts([left]),
        'SR': _mounts([right]),
      },
      'M1': _mounts(const [
        FloorPoint(4, 4),
        FloorPoint(5, 4),
        FloorPoint(6, 4),
      ]),
    },
    blocks: [
      if (split) ...const [
        math.Rectangle<double>(1.6, 1.9, .8, .2),
        math.Rectangle<double>(7.6, 5.9, .8, .2),
      ],
    ],
    barriers: const [
      (
        bounds: math.Rectangle<double>(6.9, 5.55, .2, .9),
        material: BarrierMaterial.mesh,
      ),
      (
        bounds: math.Rectangle<double>(6.9, 1.55, .2, .9),
        material: BarrierMaterial.mesh,
      ),
    ],
    antennas: [
      OpticalAntenna(
        'Remote L',
        const FloorPoint(9, 6),
        channel: 12,
        minimum: split ? 30 : 80,
      ),
      OpticalAntenna(
        'Remote R',
        const FloorPoint(9, 2),
        channel: 12,
        minimum: split ? 30 : 80,
      ),
    ],
  );
}

final oneMirrorTwoWindowsLesson = OpticalLesson(
  'endless.one-mirror-two-windows',
  _pairedHandoff(split: false),
  objective: 'Match each laser to its converter.',
  goal: 'Send laser L to converter L and laser R to converter R. Both remotes need at least 80 u.',
  notes: const [
    'The converters check which laser sent the beam. Match the L and R markings.',
    'A converter can have light at its input and still reject the laser.',
  ],
);

final dualHandoffLesson = OpticalLesson(
  'endless.dual-handoff',
  _pairedHandoff(split: true),
  objective: 'Power both local sensors and both remotes.',
  goal: 'Deliver 50 u to each local sensor and at least 30 u to each remote through its paired converter.',
  notes: const [
    'Keep half of each laser for its local sensor and send the other half toward the shared mirror.',
    'The converters accept only their marked lasers.',
  ],
);
