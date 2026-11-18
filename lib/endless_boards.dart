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
