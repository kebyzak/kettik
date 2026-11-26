import 'dart:ui';

class PitchShape {
  const PitchShape(this.a, this.u, this.v, this.aspectRatio);

  final Offset a;
  final Offset u;
  final Offset v;
  final double aspectRatio;

  Offset point(double s, double t) => a + u * s + v * t;

  List<Offset> get corners => [a, a + u, a + u + v, a + v];
}

const pitch = PitchShape(
  Offset(0.029, 0.704),
  Offset(0.543, 0.259),
  Offset(0.4, -0.37),
  350 / 270,
);

List<Offset> spotsOn(PitchShape shape, int count) {
  final rows = count <= 12 ? 2 : 3;
  final perRow = (count / rows).ceil();
  return [
    for (var i = 0; i < count; i++)
      shape.point((i ~/ perRow + 0.5) / rows, (i % perRow + 0.5) / perRow),
  ];
}
