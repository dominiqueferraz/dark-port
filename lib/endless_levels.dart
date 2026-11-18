import 'endless_boards.dart';
import 'signal_board_state.dart';
import 'tutorial.dart';

typedef SolutionStar = ({String condition, bool earned});

final antennaTestLesson = WiredLesson(
  'endless.antenna-test',
  antennaTestBoard,
  title: 'Antenna Test',
  objective: 'Bring the test antenna online.',
  goal: 'Deliver at least 30 u to the test antenna.',
  notes: const [
    'Connect the feed to the broadcaster with a patch lead.',
    'Drag the broadcaster between the two marked mounts. Its coverage reaches four grid steps.',
    'Radio loses 5 u per grid step inside coverage.',
  ],
);

final edgeOfCoverageLesson = WiredLesson(
  'endless.edge-of-coverage',
  edgeOfCoverageBoard,
  title: 'Edge of Coverage',
  objective: 'Bring the channel-12 antenna online.',
  goal: 'Deliver at least 40 u to the channel-12 service antenna.',
  notes: const [
    'The broadcaster reaches four grid steps, including the boundary.',
    'An antenna only accepts its own channel.',
  ],
);

final blindCornerLesson = WiredLesson(
  'endless.blind-corner',
  blindCornerBoard,
  title: 'Blind Corner',
  objective: 'Bring the corner antenna online.',
  goal: 'Deliver at least 35 u to the corner antenna.',
  notes: const [
    'Radio travels straight to the antenna. Concrete stops a hop, even inside coverage.',
  ],
);

const nightLightsLesson = WiredLesson(
  'endless.night-lights',
  nightLightsBoard,
  title: 'Night Lights',
  objective: 'Power all three lights at once.',
  goal: 'Deliver 75–150 u to each light.',
  notes: [
    'You have five patch leads. Each splitter divides power by its full output count.',
    'Tap a specific output socket to choose which branch to wire.',
  ],
);

final fadingSignalLesson = WiredLesson(
  'endless.fading-signal',
  fadingSignalBoard,
  title: 'Fading Signal',
  objective: 'Bring the service antenna online.',
  goal: 'Deliver at least 40 u to the service antenna.',
  notes: const [
    'Radio loses 5 u per grid step. A signal can reach an antenna and still be too weak.',
  ],
);

final relayShelfLesson = WiredLesson(
  'endless.relay-shelf',
  relayShelfBoard,
  title: 'Relay Shelf',
  objective: 'Bring the service antenna online.',
  goal: 'Deliver at least 40 u to the service antenna.',
  notes: const [
    'A powered relay passes the signal through at full strength. Its output starts a new cable leg with its own reach.',
    'Tap an output and an input to preview the lead. Its symbol shows which type the route needs. Tap the input again to install it.',
    'A shielded lead can cross the marked interference zone and reaches up to four units.',
  ],
);

final twoMastsLesson = WiredLesson(
  'endless.two-masts',
  twoMastsBoard,
  title: 'Two Masts',
  objective: 'Bring both antennas online.',
  goal: 'Deliver at least 40 u to Local and 35 u to Remote.',
  notes: const [
    'A two-way splitter gives each mast 60 u from the 120 u feed.',
    'A trunk lead reaches up to six units along a straight, marked run. Crossing the partition requires an aligned trunk feedthrough.',
    'The feedthrough carries the cable. The concrete still blocks radio.',
  ],
);

final quietSectorLesson = WiredLesson(
  'endless.quiet-sector',
  quietSectorBoard,
  title: 'Quiet Sector',
  objective: 'Power North and West. Keep the protected antenna quiet.',
  goal: 'Deliver at least 35 u to North and West with no channel-12 signal at the protected antenna.',
  notes: const [
    'Quiet means zero delivery on the monitored channel. Even a weak signal can fail this goal.',
    'Concrete can screen one antenna while radio reaches another around the edge.',
  ],
);

final cornerMirrorLesson = OpticalLesson(
  'endless.corner-mirror',
  cornerMirrorBoard,
  objective: 'Light the sensor beyond the baffle.',
  goal: 'Deliver 100 u to the sensor from its marked approach.',
  notes: const [
    'Drag the mirror between its two mounts. Tap to change which way it turns the beam.',
    'A baffle stops light. The sensor reads only from its marked approach.',
  ],
);

final splitAroundBaffleLesson = OpticalLesson(
  'endless.split-around-baffle',
  splitAroundBaffleBoard,
  objective: 'Light both sensors at once.',
  goal: 'Deliver 50 u to each sensor from its marked approach.',
  notes: const [
    'Tap the splitter to change which way its turned half travels.',
    'The mirror preserves its branch’s strength. Drag it between the two mounts to change where that branch turns.',
  ],
);

const _signalRouting = EndlessGroup.signalRouting;

enum EndlessLevel {
  antennaTest(_signalRouting, 1, 'Antenna Test'),
  edgeOfCoverage(_signalRouting, 2, 'Edge of Coverage', variantOf: 1),
  blindCorner(_signalRouting, 3, 'Blind Corner'),
  nightLights(_signalRouting, 4, 'Night Lights'),
  fadingSignal(_signalRouting, 5, 'Fading Signal'),
  relayShelf(_signalRouting, 6, 'Relay Shelf'),
  twoMasts(_signalRouting, 7, 'Two Masts'),
  quietSector(_signalRouting, 8, 'Quiet Sector'),
  cornerMirror(_signalRouting, 9, 'Corner Mirror'),
  splitAroundTheBaffle(_signalRouting, 10, 'Split Around the Baffle'),
  bothFaces(_signalRouting, 11, 'Both Faces'),
  twoBranchesTwoBends(_signalRouting, 12, 'Two Branches, Two Bends'),
  firstConversion(_signalRouting, 13, 'First Conversion'),
  meshWindow(_signalRouting, 14, 'Mesh Window'),
  aroundTheShield(_signalRouting, 15, 'Around the Shield'),
  splitTwice(_signalRouting, 16, 'Split Twice'),
  crossedChannels(_signalRouting, 17, 'Crossed Channels'),
  serviceAndInspection(_signalRouting, 18, 'Service and Inspection'),
  oneMirrorTwoWindows(_signalRouting, 19, 'One Mirror, Two Windows'),
  dualHandoff(_signalRouting, 20, 'Dual Handoff');

  const EndlessLevel(this.group, this.number, this.title, {this.variantOf});

  final int number;
  final String title;
  final EndlessGroup group;
  final int? variantOf;
  TutorialLesson? get lesson => switch (this) {
    antennaTest => antennaTestLesson,
    edgeOfCoverage => edgeOfCoverageLesson,
    blindCorner => blindCornerLesson,
    nightLights => nightLightsLesson,
    fadingSignal => fadingSignalLesson,
    relayShelf => relayShelfLesson,
    twoMasts => twoMastsLesson,
    quietSector => quietSectorLesson,
    cornerMirror => cornerMirrorLesson,
    splitAroundTheBaffle => splitAroundBaffleLesson,
    _ => null,
  };

  int get fixtureRevision => 1;

  Map<String, String> get solutionConditions => switch (this) {
    antennaTest => const {
      'coverage-boundary':
          'Deliver at least 30 u to the test antenna over a powered radio hop.',
    },
    edgeOfCoverage => const {
      'coverage-boundary': 'Deliver at least 40 u to the channel-12 service antenna at the coverage boundary.',
    },
    blindCorner => const {
      'around-concrete': 'Deliver at least 35 u to the corner antenna around the concrete wall.',
    },
    nightLights => const {
      'balanced': 'Deliver 100 u to each of the three lights.',
      'cascade': 'Deliver 150 u to Light 1 and 75 u each to Lights 2 and 3.',
    },
    fadingSignal => const {
      'four-step-hop': 'Deliver at least 40 u to the service antenna over a four-step radio hop.',
    },
    relayShelf => const {
      'shielded-relay': 'Deliver 40 u to the service antenna through a powered relay and a shielded cable leg.',
    },
    twoMasts => const {
      'trunk-fed-masts':
          'Deliver 40 u to Local and 35 u to Remote at the same time.',
    },
    quietSector => const {
      'screened-antenna': 'Bring both required antennas online while the concrete screens the protected antenna.',
    },
    cornerMirror => const {
      'clear-turn':
          'Deliver all 100 u to the sensor by turning around the baffle.',
    },
    splitAroundTheBaffle => const {
      'two-halves': 'Deliver 50 u to each sensor, with one branch routed around the baffle.',
    },
    _ => const {},
  };

  Iterable<String> get solutionIds => solutionConditions.keys;

  List<SolutionStar> starsFor(Set<String> earned) => [
    for (final MapEntry(:key, :value) in solutionConditions.entries)
      (condition: value, earned: earned.contains(key)),
  ];

  String? solutionFor(SignalBoardState state) {
    final fixture = lesson;
    if (fixture is! WiredLesson ||
        fixture.board != state.board ||
        !state.solved) {
      return null;
    }
    if (this != nightLights) return solutionIds.single;
    return switch (state.deliveries.keys
        .singleWhere((link) => link.from == 'feed')
        .to) {
      'threeWay' => 'balanced',
      'twoWayA' => 'cascade',
      _ => null,
    };
  }
}

enum EndlessGroup {
  signalRouting(1, 'Signal Routing');

  const EndlessGroup(this.number, this.title);

  final int number;
  final String title;
  Iterable<EndlessLevel> get levels =>
      EndlessLevel.values.where((level) => level.group == this);

  String sheetNumber(EndlessLevel level) => '$number.${level.number}';
}

final endlessLevelsByLessonId = Map<String, EndlessLevel>.unmodifiable({
  for (final level in EndlessLevel.values)
    if (level.lesson case final lesson?) lesson.id: level,
});
