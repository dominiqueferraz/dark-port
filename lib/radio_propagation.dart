import 'dart:math' as math;

double radioStrength(double emitted, double distance) =>
    math.max(0, emitted - 5 * distance);
