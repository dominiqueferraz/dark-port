import 'dart:convert';

import 'package:dark_port/endless_levels.dart';
import 'package:dark_port/game_save.dart';
import 'package:dark_port/optical_bay.dart';
import 'package:dark_port/tutorial.dart';
import 'package:dark_port/tutorial_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy scenes open the matching part of the tutorial', () {
    TutorialProgress migrate(String scene) => TutorialProgress.fromJson({
      'version': 1,
      'journey': scene,
      'verified': false,
      'layout': [],
    });
    final arrival = migrate('arrival');
    expect(arrival.isUnlocked(firstReflection), isTrue);
    expect(arrival.isUnlocked(dividedBeam), isFalse);
    final bayOpen = migrate('bayOpen');
    expect(bayOpen.isComplete(opticalInterlock), isTrue);
    expect(bayOpen.isUnlocked(patchLead), isTrue);
    expect(bayOpen.isUnlocked(splitRatings), isFalse);
  });

  test('legacy Test Line keeps its arrangement behind the wiring lessons', () {
    final board = GameSave(
      testLine,
      positions: {
        ...testLine.board.initialPositions,
        'beacon': const FloorPoint(1.5, 1.5),
      },
      flipped: {'attenuator'},
    );
    final migrated = TutorialProgress.fromJson(
      board.toJson()
        ..remove('board')
        ..addAll({'version': 11, 'journey': 'testLine'}),
    );
    expect(migrated.isUnlocked(patchLead), isTrue);
    expect(migrated.isUnlocked(testLine), isFalse);
    final restored = TutorialProgress.fromJson(
      jsonDecode(jsonEncode(migrated.toJson())),
    );
    final savedBoard = restored.boards[testLine.id]!;
    expect(savedBoard.positions, board.positions);
    expect(savedBoard.links, board.links);
    expect(savedBoard.flipped, board.flipped);
  });

  test('pending or optional work never bypasses a required lesson', () {
    final beforeSplit = TutorialProgress(
      completed: requiredLessons
          .takeWhile((lesson) => lesson != splitRatings)
          .map((lesson) => lesson.id)
          .toSet(),
    );
    expect(beforeSplit.isUnlocked(splitRatings), isTrue);
    expect(beforeSplit.isUnlocked(fanOut), isFalse);
    expect(beforeSplit.record(GameSave(fanOut)).boards, isEmpty);
    expect(beforeSplit.open(fanOut), same(beforeSplit));
    final afterSplit = TutorialProgress(
      completed: {...beforeSplit.completed, splitRatings.id},
    );
    expect(afterSplit.isUnlocked(fanOut), isTrue);
    expect(afterSplit.isUnlocked(benchPad), isTrue);
    expect(afterSplit.isComplete(fanOut), isFalse);
    expect(afterSplit.isUnlocked(keepalive), isFalse);
  });

  test(
    'legacy saves reveal components from completion and saved board evidence',
    () {
      final progress = TutorialProgress(
        completed: {firstReflection.id},
        boards: {dividedBeam.id: GameSave(dividedBeam)},
        endlessBoards: {relayShelfLesson.id: GameSave(relayShelfLesson)},
      );
      final old = progress.toJson()..remove('opened');
      final loaded = TutorialProgress.fromJson(jsonDecode(jsonEncode(old)));
      expect(loaded.openedLessons.toSet(), {
        firstReflection,
        dividedBeam,
        relayShelfLesson,
      });
      expect(loaded.open(twoMastsLesson).opened, {
        ...loaded.opened,
        twoMastsLesson.id,
      });
      expect(loaded.open(relayShelfLesson), same(loaded));
    },
  );

  test('Bench Pad requires a flip at every legal placement dot', () {
    const link = (from: 'attenuator', to: 'meter', input: 0, output: 0);
    final board = benchPad.board;
    final positions = board.initialPositions;
    for (final node in board.placementNodes) {
      expect(board.canMove('attenuator', node.position, positions), isTrue);
      expect(
        board.inReach(link, {...positions, 'attenuator': node.position}),
        isFalse,
      );
    }
  });
}
