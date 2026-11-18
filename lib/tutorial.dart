import 'optical_bay.dart';
import 'signal_board.dart';
import 'wired_boards.dart';

sealed class TutorialLesson {
  const TutorialLesson(
    this.id, {
    required this.title,
    required this.objective,
    required this.goal,
    this.notes = const [],
  });

  final String id;
  final String title;

  /// The short aim shown on the lesson screen.
  final String objective;

  /// The full requirements, shown at the top of the hint.
  final String goal;

  /// What the lesson teaches: controls and rules it relies on, shown in the
  /// hint below the goal. Notes explain how things work, never the solution.
  final List<String> notes;
}

class OpticalLesson extends TutorialLesson {
  OpticalLesson(
    super.id,
    this.board, {
    required super.objective,
    required super.goal,
    super.notes,
  }) : super(title: board.title);

  final OpticalLevel board;
}

class WiredLesson extends TutorialLesson {
  const WiredLesson(
    super.id,
    this.board, {
    required super.title,
    required super.objective,
    required super.goal,
    super.notes,
  });

  final SignalBoard board;
}

final firstReflection = OpticalLesson(
  'bay.reflection',
  reflectionLesson,
  objective: 'Light the latch.',
  goal: 'Get the laser beam into the latch.',
  notes: [
    'Drag a loose part to move it. It snaps to the grid.',
    'Tap a loose part to turn it a quarter turn.',
    'A mirror turns the beam 90°. Bolted parts stay where they are.',
  ],
);
final dividedBeam = OpticalLesson(
  'bay.splitting',
  splittingLesson,
  objective: 'Light both latches.',
  goal: 'Light Latch I and Latch II at the same time.',
  notes: [
    'A splitter lets half the beam pass straight through and turns the other half like a mirror.',
    'Each branch carries half the power of the beam that entered.',
  ],
);
final opticalInterlock = OpticalLesson(
  'bay.interlock',
  sealedOpticalBay,
  objective: 'Light both latches. Keep the alarm lit.',
  goal: 'Light Latch I and Latch II while the alarm stays lit the whole time.',
  notes: [
    'If the alarm goes dark, the attempt fails. Undo or reset to recover.',
    'While you drag a part, a warning shows if dropping it there would cut the alarm.',
    'The hatched baffle blocks any beam that reaches it.',
  ],
);
final patchLead = WiredLesson(
  'line.patch',
  patchLeadBoard,
  title: 'Patch Lead',
  objective: 'Power Lamp II.',
  goal: 'Power Lamp II with 90–110 u.',
  notes: [
    'Tap an output, then an input, to attach a cable.',
    'Every part has a cable reach. A dashed cable is out of reach and carries nothing.',
    'Drag a loose part to move it.',
    'Tap a part and use the broken-link icon to remove one of its cables.',
  ],
);
final splitRatings = WiredLesson(
  'line.split',
  splitRatingsBoard,
  title: 'Split Ratings',
  objective: 'Power Load A and Load B.',
  goal: 'Power Load A with 90–110 u and Load B with 45–60 u.',
  notes: [
    'A splitter shares its input evenly between its outputs: a 2-way splitter gives each output half, a 3-way a third.',
    'A share can be split again.',
    'Each reading shows a load’s current strength and the band it needs.',
  ],
);
final benchPad = WiredLesson(
  'line.pad',
  benchPadBoard,
  title: 'Bench Pad',
  objective: 'Bring the Meter to 30 u.',
  goal: 'Deliver exactly 30 u to the Meter.',
  notes: [
    'An attenuator lowers the signal passing through it. Tap it to adjust how much.',
    'Hold a loose part to mirror its ports.',
  ],
);
final keepalive = WiredLesson(
  'line.keepalive',
  keepaliveBoard,
  title: 'Keepalive',
  objective: 'Power Service. Keep the alarm blocker powered.',
  goal: 'Deliver exactly 30 u to Service while the alarm blocker stays between 25 and 35 u.',
  notes: [
    'The alarm blocker must stay within its band at every step. If it drops out, the attempt fails. Undo or reset to recover.',
    'The alarm blocker has two inputs. Signals on both add together.',
    'Pilot’s output can be lowered: tap it and adjust it like an attenuator.',
  ],
);
final testLine = WiredLesson(
  'line.capstone',
  testLineBoard,
  title: 'Test Line',
  objective: 'Power all three loads. Keep the alarm blocker powered.',
  goal: 'Power the Terminal with 45–60 u, the Recorder with 90–110 u and Service with exactly 30 u, while the alarm blocker stays between 25 and 35 u.',
  notes: [
    'This sheet uses everything from the wired lessons: cable reach, splitter shares, attenuators and the alarm blocker.',
    'The alarm blocker must stay within its band at every step.',
  ],
);
final fanOut = WiredLesson(
  'line.fanout',
  fanOutBoard,
  title: 'Four-way fan-out',
  objective: 'Power all four loads.',
  goal: 'Deliver 75 u to each of North, East, South and West.',
  notes: [
    'A 4-way splitter gives each of its four outputs a quarter of its input.',
    'Its outputs are on the sides, top and bottom.',
  ],
);

final requiredLessons = List<TutorialLesson>.unmodifiable([
  firstReflection,
  dividedBeam,
  opticalInterlock,
  patchLead,
  splitRatings,
  benchPad,
  keepalive,
  testLine,
]);

final practiceLessons = Map<TutorialLesson, TutorialLesson>.unmodifiable({
  fanOut: splitRatings,
});

final lessonsById = Map<String, TutorialLesson>.unmodifiable({
  for (final lesson in [...requiredLessons, ...practiceLessons.keys])
    lesson.id: lesson,
});

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// A lesson's drawing-sheet number: its place on the required path, or its
/// parent's number with a letter for a practice branch.
String sheetNumber(TutorialLesson lesson) {
  final index = requiredLessons.indexOf(lesson);
  if (index >= 0) return _twoDigits(index + 1);
  return '${_twoDigits(requiredLessons.indexOf(practiceLessons[lesson]!) + 1)}A';
}

/// The sheet number with the size of the set, as a title block shows it.
String sheetOfSet(TutorialLesson lesson) =>
    '${sheetNumber(lesson)}/${_twoDigits(requiredLessons.length)}';
