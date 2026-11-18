import 'dart:math' as math;

import 'optical_bay.dart';
import 'placement_nodes.dart';
import 'signal_board.dart';

const _testAntenna = SignalDevice(
  'testAntenna',
  'Test antenna',
  SignalDeviceKind.antenna,
  SignalPoint(6.5, 1.5),
  minimumStrength: 30,
  fixed: true,
);

const _serviceAntenna = SignalDevice(
  'serviceAntenna',
  'Service antenna',
  SignalDeviceKind.antenna,
  SignalPoint(6.5, 1.5),
  minimumStrength: 40,
  fixed: true,
);

const _cornerAntenna = SignalDevice(
  'cornerAntenna',
  'Corner antenna',
  SignalDeviceKind.antenna,
  SignalPoint(6.5, 1.5),
  minimumStrength: 35,
  fixed: true,
);

const _straightMounts = [
  (position: SignalPoint(1.5, 1.5), intersection: false),
  (position: SignalPoint(2.5, 1.5), intersection: false),
];

SignalBoard _radioBoard({
  required SignalDevice target,
  required int range,
  List<PlacementNode> mounts = _straightMounts,
  List<SignalDevice> decoys = const [],
  List<RadioWall> walls = const [],
}) => SignalBoard(
  size: 7,
  height: 3,
  placementNodes: mounts,
  patchLeadStock: 1,
  radioWalls: walls,
  devices: [
    const SignalDevice(
      'feed',
      'Feed',
      SignalDeviceKind.transmitter,
      SignalPoint(.5, 1.5),
      strength: 60,
      fixed: true,
    ),
    SignalDevice(
      'broadcaster',
      'Broadcaster',
      SignalDeviceKind.broadcaster,
      mounts.first.position,
      radioRange: range,
    ),
    target,
    ...decoys,
  ],
  goals: [target],
);

final antennaTestBoard = _radioBoard(target: _testAntenna, range: 4);

final edgeOfCoverageBoard = _radioBoard(
  target: _serviceAntenna,
  range: 4,
  decoys: const [
    SignalDevice(
      'channelNine',
      'Ch 9 antenna',
      SignalDeviceKind.antenna,
      SignalPoint(1.5, 2.5),
      channel: 9,
      fixed: true,
    ),
  ],
);

final blindCornerBoard = _radioBoard(
  target: _cornerAntenna,
  range: 5,
  mounts: const [
    (position: SignalPoint(2.5, .5), intersection: false),
    (position: SignalPoint(2.5, 2.5), intersection: false),
  ],
  walls: const [RadioWall(4.5, 0, 1.25)],
);

final fadingSignalBoard = _radioBoard(target: _serviceAntenna, range: 6);

const _lightOne = SignalDevice(
  'light1',
  'Light 1',
  SignalDeviceKind.receiver,
  SignalPoint(5.5, 2),
  minimumStrength: 75,
  maximumStrength: 150,
  fixed: true,
);

const _lightTwo = SignalDevice(
  'light2',
  'Light 2',
  SignalDeviceKind.receiver,
  SignalPoint(7.5, 3.5),
  minimumStrength: 75,
  maximumStrength: 150,
  fixed: true,
);

const _lightThree = SignalDevice(
  'light3',
  'Light 3',
  SignalDeviceKind.receiver,
  SignalPoint(7, 4.5),
  minimumStrength: 75,
  maximumStrength: 150,
  fixed: true,
);

const nightLightsBoard = SignalBoard(
  size: 8,
  height: 5,
  placementNodes: [],
  patchLeadStock: 5,
  devices: [
    SignalDevice(
      'feed',
      'Feed',
      SignalDeviceKind.transmitter,
      SignalPoint(.5, 1.5),
      strength: 300,
      cableRange: 2,
      fixed: true,
    ),
    SignalDevice(
      'threeWay',
      'Three-way',
      SignalDeviceKind.splitter,
      SignalPoint(3, 1.5),
      splitter: SplitterType.threeWay,
      cableRange: 6,
      fixed: true,
    ),
    SignalDevice(
      'twoWayA',
      'Two-way A',
      SignalDeviceKind.splitter,
      SignalPoint(1.5, 3),
      splitter: SplitterType.twoWay,
      cableRange: 4,
      fixed: true,
    ),
    SignalDevice(
      'twoWayB',
      'Two-way B',
      SignalDeviceKind.splitter,
      SignalPoint(5.5, 3.5),
      splitter: SplitterType.twoWay,
      cableRange: 2,
      fixed: true,
    ),
    _lightOne,
    _lightTwo,
    _lightThree,
  ],
  goals: [_lightOne, _lightTwo, _lightThree],
);

const _relayMounts = [
  (position: SignalPoint(1, 3.5), intersection: false),
  (position: SignalPoint(2, 2.12), intersection: false),
  (position: SignalPoint(3, 2.12), intersection: false),
];
const _shelfMastMounts = [
  (position: SignalPoint(5.37, .75), intersection: false),
  (position: SignalPoint(6.37, .75), intersection: false),
];
const _shelfAntenna = SignalDevice(
  'serviceAntenna',
  'Service antenna',
  SignalDeviceKind.antenna,
  SignalPoint(10.37, .75),
  minimumStrength: 40,
  fixed: true,
);

final relayShelfBoard = SignalBoard(
  size: 11,
  height: 4,
  placementNodes: [..._relayMounts, ..._shelfMastMounts],
  patchLeadStock: 1,
  shieldedLeadStock: 1,
  interference: const math.Rectangle<double>(4, .4, .75, .7),
  devices: [
    const SignalDevice(
      'feed',
      'Feed',
      SignalDeviceKind.transmitter,
      SignalPoint(.63, .75),
      strength: 60,
      cableRange: 4,
      fixed: true,
    ),
    SignalDevice(
      'relay',
      'Relay',
      SignalDeviceKind.relay,
      _relayMounts.first.position,
      cableRange: 4,
      mounts: _relayMounts,
    ),
    SignalDevice(
      'broadcaster',
      'Broadcaster',
      SignalDeviceKind.broadcaster,
      _shelfMastMounts.first.position,
      radioRange: 6,
      mounts: _shelfMastMounts,
    ),
    _shelfAntenna,
  ],
  goals: const [_shelfAntenna],
  cableCorridors: [
    for (final x in [5.0, 6.0])
      CableCorridor([const SignalPoint(1, .75), SignalPoint(x, .75)]),
    for (final x in [2.0, 3.0]) ...[
      CableCorridor([
        const SignalPoint(1, .75),
        const SignalPoint(1.2, .75),
        const SignalPoint(1.2, 2.12),
        SignalPoint(x - .37, 2.12),
      ]),
      for (final end in [5.0, 6.0])
        CableCorridor([
          SignalPoint(x + .37, 2.12),
          SignalPoint(x + .60, 2.12),
          SignalPoint(x + .60, .75),
          SignalPoint(end, .75),
        ]),
    ],
  ],
);

const _localMastMounts = [
  (position: SignalPoint(3.5, .5), intersection: false),
  (position: SignalPoint(3.5, 1.5), intersection: false),
];
const _localAntenna = SignalDevice(
  'localAntenna',
  'Local antenna',
  SignalDeviceKind.antenna,
  SignalPoint(.5, 2.5),
  minimumStrength: 40,
  fixed: true,
);
const _remoteAntenna = SignalDevice(
  'remoteAntenna',
  'Remote antenna',
  SignalDeviceKind.antenna,
  SignalPoint(12.74, 3.5),
  minimumStrength: 35,
  fixed: true,
);

final twoMastsBoard = SignalBoard(
  size: 14,
  height: 5,
  placementNodes: _localMastMounts,
  patchLeadStock: 2,
  trunkLeadStock: 1,
  radioWalls: const [RadioWall(5.5, 0, 5)],
  feedthroughs: {
    const SignalPoint(5.5, 2.5): const {LeadType.trunk},
  },
  devices: [
    const SignalDevice(
      'feed',
      'Feed',
      SignalDeviceKind.transmitter,
      SignalPoint(.63, 4.5),
      strength: 120,
      fixed: true,
    ),
    const SignalDevice(
      'splitter',
      'Two-way',
      SignalDeviceKind.splitter,
      SignalPoint(2, 2.5),
      splitter: SplitterType.twoWay,
      fixed: true,
    ),
    SignalDevice(
      'localMast',
      'Local mast',
      SignalDeviceKind.broadcaster,
      _localMastMounts.first.position,
      radioRange: 6,
      mounts: _localMastMounts,
    ),
    const SignalDevice(
      'remoteMast',
      'Remote mast',
      SignalDeviceKind.broadcaster,
      SignalPoint(8.74, 2.5),
      radioRange: 6,
      fixed: true,
    ),
    _localAntenna,
    _remoteAntenna,
  ],
  goals: const [_localAntenna, _remoteAntenna],
  cableCorridors: [
    const CableCorridor([
      SignalPoint(1, 4.5),
      SignalPoint(1.2, 4.5),
      SignalPoint(1.2, 2.5),
      SignalPoint(1.63, 2.5),
    ]),
    const CableCorridor([
      SignalPoint(2.37, 2.5),
      SignalPoint(8.37, 2.5),
    ], trunk: true),
    for (final mount in _localMastMounts)
      CableCorridor([
        const SignalPoint(2.29, 2.14),
        SignalPoint(2.29, mount.position.y),
        SignalPoint(3.13, mount.position.y),
      ]),
  ],
);

const _quietMounts = [
  (position: SignalPoint(1.5, .5), intersection: false),
  (position: SignalPoint(1.5, 1.5), intersection: false),
  (position: SignalPoint(4.5, 2.5), intersection: false),
];
const _northAntenna = SignalDevice(
  'northAntenna',
  'North antenna',
  SignalDeviceKind.antenna,
  SignalPoint(5.5, .5),
  minimumStrength: 35,
  fixed: true,
);
const _westAntenna = SignalDevice(
  'westAntenna',
  'West antenna',
  SignalDeviceKind.antenna,
  SignalPoint(3.5, 1.5),
  minimumStrength: 35,
  fixed: true,
);
const _protectedAntenna = SignalDevice(
  'protected',
  'Protected antenna',
  SignalDeviceKind.antenna,
  SignalPoint(5.5, 1.5),
  mustBeQuiet: true,
  fixed: true,
);

final quietSectorBoard = SignalBoard(
  size: 7,
  height: 4,
  patchLeadStock: 1,
  placementNodes: _quietMounts,
  radioWalls: const [RadioWall(5, 1.4, 3.1)],
  devices: [
    const SignalDevice(
      'feed',
      'Feed',
      SignalDeviceKind.transmitter,
      SignalPoint(2.5, 2.5),
      strength: 60,
      cableRange: 4,
      fixed: true,
    ),
    SignalDevice(
      'broadcaster',
      'Broadcaster',
      SignalDeviceKind.broadcaster,
      _quietMounts.first.position,
      radioRange: 5,
      mounts: _quietMounts,
    ),
    _northAntenna,
    _westAntenna,
    _protectedAntenna,
  ],
  goals: const [_northAntenna, _westAntenna, _protectedAntenna],
);

const _opticalFloor = math.Rectangle<double>(-6.3, -4.47, 12.6, 7.647);
const _opticalSource = FloorPoint(-5.21, -1.845);
const _opticalSourceFoot = FloorPoint(-5.74, -1.845);
const _cornerMount = FloorPoint(-2.625, -1.845);

const cornerMirrorBoard = OpticalLevel(
  title: 'Corner Mirror',
  floor: _opticalFloor,
  laser: _opticalSource,
  laserFoot: _opticalSourceFoot,
  direction: BeamDirection.east,
  blocks: [math.Rectangle<double>(-3.3, -.48, 4.4, .28)],
  initial: [Optic('M1', OpticKind.mirror, _cornerMount)],
  mounts: {
    'M1': [
      (position: _cornerMount, intersection: false),
      (position: FloorPoint(2.625, -1.845), intersection: false),
    ],
  },
  receivers: [
    OpticalReceiver(
      'Sensor',
      FloorPoint(2.625, 3.177),
      BeamDirection.north,
      requiredPower: 100,
    ),
  ],
  goal: {0},
);

const _shortMirrorMount = FloorPoint(-2.625, .255);
const splitAroundBaffleBoard = OpticalLevel(
  title: 'Split Around the Baffle',
  floor: _opticalFloor,
  laser: _opticalSource,
  laserFoot: _opticalSourceFoot,
  direction: BeamDirection.east,
  blocks: [math.Rectangle<double>(-1.65, -.10, 5.15, .56)],
  initial: [
    Optic('S1', OpticKind.splitter, _cornerMount, turned: true),
    Optic('M1', OpticKind.mirror, _shortMirrorMount),
  ],
  mounts: {
    'S1': [(position: _cornerMount, intersection: false)],
    'M1': [
      (position: _shortMirrorMount, intersection: false),
      (position: FloorPoint(-2.625, 1.305), intersection: false),
    ],
  },
  receivers: [
    OpticalReceiver(
      'Local sensor',
      FloorPoint(6.3, -1.845),
      BeamDirection.east,
      requiredPower: 50,
    ),
    OpticalReceiver(
      'Far sensor',
      FloorPoint(6.3, 1.305),
      BeamDirection.east,
      requiredPower: 50,
    ),
  ],
  goal: {0, 1},
);
