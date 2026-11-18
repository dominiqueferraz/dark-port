import 'package:dark_port/drafting_annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = Rect.fromLTWH(0, 0, 160, 120);
  const anchor = Offset(66, 62);
  const preferred = Offset(32, 0);

  test('a clear preferred leader attaches to the drawn casing', () {
    final annotations = DraftingAnnotations(bounds: bounds);
    final balloon = annotations.placeBalloon(
      anchor: anchor,
      radius: 8,
      reach: 10,
      gaps: const [10],
      preferredOffset: preferred,
      reachAt: (_) => 13,
    );

    expect(balloon, (center: anchor + preferred, reach: 13.0));
    expect(annotations.hasRoom(balloon!.center, 0), isFalse);
  });

  test('a jack under the preferred leader forces a clear alternative', () {
    const jack = Offset(82, 62);
    final annotations = DraftingAnnotations(
      bounds: bounds,
      leaderObstacles: const [(center: jack, radius: 4)],
    );
    final balloon = annotations.placeBalloon(
      anchor: anchor,
      radius: 8,
      reach: 10,
      gaps: const [10],
      preferredOffset: preferred,
    )!;

    expect(balloon.center, isNot(anchor + preferred));
    final vector = balloon.center - anchor;
    final direction = vector / vector.distance;
    expect(
      distanceToDraftingSegment(
        jack,
        anchor + direction * balloon.reach,
        balloon.center - direction * 8,
      ),
      greaterThanOrEqualTo(4),
    );
  });

  test('notes clear an obstacle, a live trace and the drawing edge', () {
    final annotations = DraftingAnnotations(
      bounds: bounds,
      obstacles: const [Rect.fromLTWH(15, 15, 40, 25)],
      traces: const [(Offset(100, 20), Offset(100, 100))],
    );
    expect(annotations.hasRoom(const Offset(57, 35), 5), isFalse);
    expect(annotations.hasRoom(const Offset(96, 60), 5), isFalse);
    expect(annotations.hasRoom(const Offset(3, 60), 5), isFalse);
    expect(annotations.hasRoom(const Offset(70, 60), 5), isTrue);
  });

  test('the whole label clears walls, diagonal traces and other notes', () {
    final annotations = DraftingAnnotations(
      bounds: bounds,
      obstacles: const [Rect.fromLTWH(60, 0, 5, 120)],
      traces: const [(Offset(70, 20), Offset(104, 54))],
    );
    const size = Size(36, 12);
    final label = annotations.placeLabel(size, const [
      Offset(78, 72), // Its left edge sits on the wall.
      Offset(99, 40), // A trace clips the upper-left side.
      Offset(118, 72),
    ]);
    expect(label?.center, const Offset(118, 72));
    expect(
      annotations.placeLabel(size, const [
        Offset(124, 78),
        Offset(118, 97),
      ])?.center,
      const Offset(118, 97),
    );
  });
}
