import 'package:flutter_test/flutter_test.dart';
import 'package:kettik/ui/pitch_geometry.dart';

/// Inverts [PitchShape.point] to (s, t) so we can tell whether a spot is on the pitch.
(double, double) toPitch(PitchShape p, Offset o) {
  final d = o - p.a;
  final det = p.u.dx * p.v.dy - p.u.dy * p.v.dx;
  return ((d.dx * p.v.dy - d.dy * p.v.dx) / det, (p.u.dx * d.dy - p.u.dy * d.dx) / det);
}

void main() {
  for (final count in [6, 10, 12, 15, 16, 22]) {
    test('$count places get $count distinct spots inside the pitch', () {
      final spots = spotsOn(pitch, count);
      expect(spots, hasLength(count));
      expect(spots.toSet(), hasLength(count));
      for (final s in spots) {
        final (u, v) = toPitch(pitch, s);
        expect(u, inExclusiveRange(0, 1));
        expect(v, inExclusiveRange(0, 1));
      }
    });
  }

  test('fifteen places stand in three rows of five', () {
    final spots = spotsOn(pitch, 15);
    final rows = spots.map((s) => toPitch(pitch, s).$1.toStringAsFixed(3)).toSet();
    expect(rows, hasLength(3));
  });
}
