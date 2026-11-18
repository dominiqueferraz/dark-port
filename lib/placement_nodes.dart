import 'dart:math' as math;

typedef PlacementNode = ({math.Point<double> position, bool intersection});

List<PlacementNode> buildPlacementNodes({
  required math.Point<double> origin,
  required double tileSize,
  required int columns,
  required int rows,
}) => List.unmodifiable([
  for (var row = 0; row < rows; row++)
    for (var column = 0; column < columns; column++)
      (
        position: math.Point(
          origin.x + (column + .5) * tileSize,
          origin.y + (row + .5) * tileSize,
        ),
        intersection: false,
      ),
  for (var row = 1; row < rows; row++)
    for (var column = 1; column < columns; column++)
      (
        position: math.Point(
          origin.x + column * tileSize,
          origin.y + row * tileSize,
        ),
        intersection: true,
      ),
]);

PlacementNode? nearestPlacementNode(
  math.Point<double> point,
  Iterable<PlacementNode> nodes,
) {
  PlacementNode? closest;
  var distance = double.infinity;
  for (final node in nodes) {
    final delta = point.squaredDistanceTo(node.position);
    if (delta < distance) {
      closest = node;
      distance = delta;
    }
  }
  return closest;
}
