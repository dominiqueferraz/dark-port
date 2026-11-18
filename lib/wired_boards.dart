import 'placement_nodes.dart';
import 'signal_board.dart';

const _testLineTerminal = SignalDevice(
  'terminal',
  'Terminal',
  SignalDeviceKind.receiver,
  SignalPoint(5.5, 2.5),
  minimumStrength: 45,
  maximumStrength: 60,
);

const _testLineRecorder = SignalDevice(
  'recorder',
  'Recorder',
  SignalDeviceKind.receiver,
  SignalPoint(4.5, .5),
  minimumStrength: 90,
  maximumStrength: 110,
);

const _testLineService = SignalDevice(
  'service',
  'Service',
  SignalDeviceKind.receiver,
  SignalPoint(1.5, 4.5),
  minimumStrength: 30,
  maximumStrength: 30,
  requiredSource: 'pilot',
);

const _testLineSize = 6.0;
const _testLineHeight = 7.0;
const _alarmPilot = SignalDevice(
  'pilot',
  'Pilot',
  SignalDeviceKind.transmitter,
  SignalPoint(.5, 5.5),
  strength: 30,
  cableRange: 3,
  initialLoss: 0,
  alternateTint: true,
);
const _alarmBlocker = SignalDevice(
  'alarmBlocker',
  'Alarm blocker',
  SignalDeviceKind.receiver,
  SignalPoint(2.5, 5.5),
  minimumStrength: 25,
  maximumStrength: 35,
  dualInput: true,
);
final testLineBoard = SignalBoard(
  size: _testLineSize,
  height: _testLineHeight,
  alarm: (blocker: _alarmBlocker, source: 'beacon'),
  initialLinks: const [
    (from: 'pilot', to: 'alarmBlocker', input: 0, output: 0),
  ],
  placementNodes: buildPlacementNodes(
    origin: const SignalPoint(0, 0),
    tileSize: 1,
    columns: _testLineSize.toInt(),
    rows: _testLineHeight.toInt(),
  ),
  devices: const [
    SignalDevice(
      'beacon',
      'Beacon',
      SignalDeviceKind.transmitter,
      SignalPoint(.5, 2.5),
      strength: 300,
      cableRange: 9,
    ),
    SignalDevice(
      'twoWay',
      '2-way splitter',
      SignalDeviceKind.splitter,
      SignalPoint(4.5, 2.5),
      splitter: SplitterType.twoWay,
    ),
    SignalDevice(
      'threeWay',
      '3-way splitter',
      SignalDeviceKind.splitter,
      SignalPoint(2.5, 2.5),
      splitter: SplitterType.threeWay,
    ),
    SignalDevice(
      'fourWay',
      '4-way splitter',
      SignalDeviceKind.splitter,
      SignalPoint(5.5, 5.5),
      splitter: SplitterType.fourWay,
    ),
    SignalDevice(
      'attenuator',
      'Attenuator',
      SignalDeviceKind.attenuator,
      SignalPoint(4.5, 6.5),
      cableRange: 5,
      initialLoss: 20,
    ),
    _testLineTerminal,
    _testLineRecorder,
    _testLineService,
    _alarmPilot,
    _alarmBlocker,
  ],
  goals: const [_testLineTerminal, _testLineRecorder, _testLineService],
);

SignalBoard _bench({
  required int width,
  required int height,
  required List<SignalDevice> devices,
  required List<SignalDevice> goals,
  List<SignalLink> links = const [],
  Set<String> flipped = const {},
  List<PlacementNode>? dots,
  ({SignalDevice blocker, String source})? alarm,
}) => SignalBoard(
  size: width.toDouble(),
  height: height.toDouble(),
  placementNodes:
      dots ??
      buildPlacementNodes(
        origin: const SignalPoint(0, 0),
        tileSize: 1,
        columns: width,
        rows: height,
      ),
  devices: devices,
  goals: goals,
  initialLinks: links,
  initialFlipped: flipped,
  alarm: alarm,
);

const _lampOne = SignalDevice(
  'lampOne',
  'Lamp I',
  SignalDeviceKind.receiver,
  SignalPoint(3.5, 1.5),
  minimumStrength: 90,
  maximumStrength: 110,
  fixed: true,
);
const _lampTwo = SignalDevice(
  'lampTwo',
  'Lamp II',
  SignalDeviceKind.receiver,
  SignalPoint(5.5, 2.5),
  minimumStrength: 90,
  maximumStrength: 110,
  fixed: true,
);
final patchLeadBoard = _bench(
  width: 6,
  height: 5,
  devices: const [
    SignalDevice(
      'feed',
      'Feed',
      SignalDeviceKind.transmitter,
      SignalPoint(.5, 4.5),
      strength: 100,
    ),
    _lampOne,
    _lampTwo,
  ],
  goals: const [_lampTwo],
  links: const [(from: 'feed', to: 'lampOne', input: 0, output: 0)],
);

const _benchBeacon = SignalDevice(
  'beacon',
  'Beacon',
  SignalDeviceKind.transmitter,
  SignalPoint(.5, 2.5),
  strength: 300,
  cableRange: 9,
  fixed: true,
);
const _loadA = SignalDevice(
  'loadA',
  'Load A',
  SignalDeviceKind.receiver,
  SignalPoint(5.5, .5),
  minimumStrength: 90,
  maximumStrength: 110,
  fixed: true,
);
const _loadB = SignalDevice(
  'loadB',
  'Load B',
  SignalDeviceKind.receiver,
  SignalPoint(5.5, 2.5),
  minimumStrength: 45,
  maximumStrength: 60,
  fixed: true,
);
final splitRatingsBoard = _bench(
  width: 6,
  height: 5,
  devices: const [
    _benchBeacon,
    SignalDevice(
      'twoWay',
      '2-way splitter',
      SignalDeviceKind.splitter,
      SignalPoint(4.5, 2.5),
      splitter: SplitterType.twoWay,
    ),
    SignalDevice(
      'threeWay',
      '3-way splitter',
      SignalDeviceKind.splitter,
      SignalPoint(2.5, 2.5),
      splitter: SplitterType.threeWay,
    ),
    _loadA,
    _loadB,
  ],
  goals: const [_loadA, _loadB],
);

const _meter = SignalDevice(
  'meter',
  'Meter',
  SignalDeviceKind.receiver,
  SignalPoint(.5, 2.5),
  minimumStrength: 30,
  maximumStrength: 30,
  fixed: true,
);
final benchPadBoard = _bench(
  width: 6,
  height: 4,
  devices: const [
    SignalDevice(
      'feed',
      'Feed',
      SignalDeviceKind.transmitter,
      SignalPoint(5.5, 2.5),
      strength: 40,
      fixed: true,
    ),
    SignalDevice(
      'attenuator',
      'Attenuator',
      SignalDeviceKind.attenuator,
      SignalPoint(3.5, 1.5),
      cableRange: 2,
      initialLoss: 0,
    ),
    _meter,
  ],
  goals: const [_meter],
  dots: const [
    (position: SignalPoint(3.5, 1.5), intersection: false),
    (position: SignalPoint(2.5, 2.5), intersection: false),
  ],
);

const _benchBlocker = SignalDevice(
  'alarmBlocker',
  'Alarm blocker',
  SignalDeviceKind.receiver,
  SignalPoint(2.5, 2.5),
  minimumStrength: 25,
  maximumStrength: 35,
  dualInput: true,
  fixed: true,
);
const _benchService = SignalDevice(
  'service',
  'Service',
  SignalDeviceKind.receiver,
  SignalPoint(1.5, 3.5),
  minimumStrength: 30,
  maximumStrength: 30,
  requiredSource: 'pilot',
  fixed: true,
);
final keepaliveBoard = _bench(
  width: 6,
  height: 4,
  devices: const [
    SignalDevice(
      'pilot',
      'Pilot',
      SignalDeviceKind.transmitter,
      SignalPoint(.5, 2.5),
      strength: 30,
      initialLoss: 0,
      fixed: true,
      alternateTint: true,
    ),
    SignalDevice(
      'aux',
      'Auxiliary',
      SignalDeviceKind.transmitter,
      SignalPoint(.5, .5),
      strength: 30,
      cableRange: 5,
      fixed: true,
    ),
    SignalDevice(
      'beacon',
      'Beacon',
      SignalDeviceKind.transmitter,
      SignalPoint(5.5, 2.5),
      strength: 25,
      cableRange: 5,
      fixed: true,
    ),
    SignalDevice(
      'attenuator',
      'Attenuator',
      SignalDeviceKind.attenuator,
      SignalPoint(3.5, 2.5),
      initialLoss: 20,
      fixed: true,
    ),
    _benchBlocker,
    _benchService,
  ],
  goals: const [_benchService],
  alarm: (blocker: _benchBlocker, source: 'beacon'),
  flipped: const {'attenuator'},
  links: const [
    (from: 'pilot', to: 'alarmBlocker', input: 0, output: 0),
    (from: 'beacon', to: 'attenuator', input: 0, output: 0),
  ],
);

const _fanOutLoads = [
  SignalDevice(
    'north',
    'North',
    SignalDeviceKind.receiver,
    SignalPoint(3.5, .5),
    minimumStrength: 75,
    maximumStrength: 75,
    fixed: true,
  ),
  SignalDevice(
    'east',
    'East',
    SignalDeviceKind.receiver,
    SignalPoint(5.5, 1.5),
    minimumStrength: 75,
    maximumStrength: 75,
    fixed: true,
  ),
  SignalDevice(
    'south',
    'South',
    SignalDeviceKind.receiver,
    SignalPoint(3.5, 4.5),
    minimumStrength: 75,
    maximumStrength: 75,
    fixed: true,
  ),
  SignalDevice(
    'west',
    'West',
    SignalDeviceKind.receiver,
    SignalPoint(.5, 4.5),
    minimumStrength: 75,
    maximumStrength: 75,
    fixed: true,
  ),
];
final fanOutBoard = _bench(
  width: 6,
  height: 5,
  devices: const [
    _benchBeacon,
    SignalDevice(
      'fourWay',
      '4-way splitter',
      SignalDeviceKind.splitter,
      SignalPoint(3.5, 2.5),
      splitter: SplitterType.fourWay,
      fixed: true,
    ),
    ..._fanOutLoads,
  ],
  goals: _fanOutLoads,
);
