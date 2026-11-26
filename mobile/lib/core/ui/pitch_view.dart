import 'package:flutter/material.dart';

import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/pitch_geometry.dart';
import 'package:kettik/core/ui/theme.dart';

class PitchView extends StatelessWidget {
  const PitchView({
    super.key,
    required this.kinds,
    this.selected,
    this.pulse,
    this.grass = true,
    this.numbers = true,
    this.spotScale,
    this.overlay,
  });

  final List<SpotKind> kinds;
  final int? selected;
  final int? pulse;
  final bool grass;
  final bool numbers;
  final double Function(int index)? spotScale;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: pitch.aspectRatio,
    child: LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final d = w * 0.074;
        final spots = spotsOn(pitch, kinds.length);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PitchPainter(grass: grass)),
            ),
            if (overlay != null) Positioned(left: 20, top: 16, child: overlay!),
            for (var i = 0; i < spots.length; i++)
              Positioned(
                left: spots[i].dx * w - d / 2,
                top: spots[i].dy * h - d / 2,
                child: Transform.scale(
                  scale:
                      (spotScale?.call(i) ?? 1) *
                      (selected == i + 1 ? 1.35 : 1),
                  child: _Spot(
                    number: numbers ? i + 1 : null,
                    kind: kinds[i],
                    size: d,
                    selected: selected == i + 1,
                    pulse: pulse == i + 1,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter({required this.grass});

  final bool grass;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
    final field = Path()
      ..addPolygon([for (final c in pitch.corners) at(c)], true);
    if (grass) canvas.drawPath(field, Paint()..color = K.pitch);
    final chalk = Paint()
      ..color = K.sheet.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(field, chalk);
    canvas.drawLine(at(pitch.point(0, 0.5)), at(pitch.point(1, 0.5)), chalk);
    final centre = at(pitch.point(0.5, 0.5));
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(-0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.22,
        height: size.width * 0.1,
      ),
      chalk,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PitchPainter old) => old.grass != grass;
}

class _Spot extends StatelessWidget {
  const _Spot({
    required this.number,
    required this.kind,
    required this.size,
    required this.selected,
    required this.pulse,
  });

  final int? number;
  final SpotKind kind;
  final double size;
  final bool selected;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final fg = switch (kind) {
      SpotKind.paid => K.ink,
      SpotKind.mine => K.sheet,
      _ => K.sheet,
    };
    final label = number == null
        ? null
        : Center(
            child: Text('$number', style: display(size * 0.42, color: fg)),
          );
    final Widget spot = kind == SpotKind.free
        ? CustomPaint(
            painter: DashedCircle(K.sheet.withValues(alpha: 0.9), width: 2),
            child: label,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (kind) {
                SpotKind.paid => K.sheet,
                SpotKind.mine => K.ink,
                _ => null,
              },
              border: kind == SpotKind.held
                  ? Border.all(color: K.sheet, width: 2.5)
                  : null,
              boxShadow: kind == SpotKind.paid
                  ? const [
                      BoxShadow(color: Color(0x4022302A), offset: Offset(0, 2)),
                    ]
                  : null,
            ),
            child: label,
          );
    final framed = selected
        ? DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: K.ink, width: 2.5),
            ),
            child: Padding(padding: const EdgeInsets.all(1), child: spot),
          )
        : spot;
    return SizedBox.square(
      dimension: size,
      child: pulse ? _Pulse(child: framed) : framed,
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.disableAnimationsOf(context) ? _c.stop() : _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final t = Curves.easeOut.transform(_c.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: K.ink.withValues(alpha: 0.35 * (1 - t)),
              spreadRadius: 8 * t,
            ),
          ],
        ),
        child: child,
      );
    },
  );
}
