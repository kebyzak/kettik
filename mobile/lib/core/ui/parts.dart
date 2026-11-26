import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/ui/theme.dart';

enum SpotKind { paid, held, free, mine }

SpotKind kindOf(Place place, Player? me) => switch (place) {
  FreePlace() => SpotKind.free,
  HeldPlace(:final player) =>
    player.id == me?.id ? SpotKind.mine : SpotKind.held,
  PaidPlace(:final player) =>
    player.id == me?.id ? SpotKind.mine : SpotKind.paid,
};

List<SpotKind> kindsOf(Game g, Player? me) => [
  for (final p in g.places) kindOf(p, me),
];

class EverySecond extends StatefulWidget {
  const EverySecond({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<EverySecond> createState() => _EverySecondState();
}

class _EverySecondState extends State<EverySecond> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class DashedCircle extends CustomPainter {
  const DashedCircle(this.color, {this.width = 1.5});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final rect = Offset.zero & size;
    const dashes = 12;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        rect.deflate(width / 2),
        i * 2 * math.pi / dashes,
        math.pi / dashes,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DashedCircle old) =>
      old.color != color || old.width != width;
}

class PlaceChip extends StatelessWidget {
  const PlaceChip(this.number, this.kind, {super.key, this.size = 28});

  final int number;
  final SpotKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (fill, fg, border) = switch (kind) {
      SpotKind.paid => (K.pitch, K.ink, null),
      SpotKind.mine => (K.ink, K.sheet, null),
      SpotKind.held => (null, K.signal, Border.all(color: K.signal, width: 2)),
      SpotKind.free => (null, K.ink2, null),
    };
    final label = Center(
      child: Text('$number', style: display(11, color: fg)),
    );
    return SizedBox.square(
      dimension: size,
      child: kind == SpotKind.free
          ? CustomPaint(painter: const DashedCircle(K.dash), child: label)
          : DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: border,
              ),
              child: label,
            ),
    );
  }
}

class DotStrip extends StatelessWidget {
  const DotStrip(
    this.kinds, {
    super.key,
    this.size = 8,
    this.faded = false,
    this.maxWidth,
  });

  final List<SpotKind> kinds;
  final double size;
  final bool faded;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    Widget dot(SpotKind k) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (k) {
          SpotKind.paid || SpotKind.mine => faded ? K.faded : K.pitch,
          SpotKind.held => null,
          SpotKind.free => K.line,
        },
        border: k == SpotKind.held
            ? Border.all(color: K.signal, width: 2)
            : null,
      ),
    );
    final strip = Wrap(
      spacing: 3,
      runSpacing: 3,
      alignment: WrapAlignment.end,
      children: [for (final k in kinds) dot(k)],
    );
    return ExcludeSemantics(
      child: maxWidth == null ? strip : SizedBox(width: maxWidth, child: strip),
    );
  }
}

enum PillStyle { primary, outline, quiet }

class PillButton extends StatelessWidget {
  const PillButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.style = PillStyle.primary,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(height / 2),
      side: style == PillStyle.outline
          ? const BorderSide(color: K.ink, width: 2)
          : BorderSide.none,
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: shape,
          backgroundColor: style == PillStyle.primary
              ? K.ink
              : Colors.transparent,
          foregroundColor: style == PillStyle.primary
              ? K.sheet
              : (style == PillStyle.quiet ? K.ink2 : K.ink),
          disabledBackgroundColor: style == PillStyle.primary
              ? K.verge
              : Colors.transparent,
          disabledForegroundColor: K.ink2,
          textStyle: style == PillStyle.primary
              ? display(15, weight: 600)
              : body(15, weight: 600),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.height = 20});

  final double height;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/brand/wordmark.svg',
    height: height,
    semanticsLabel: 'kettik',
    colorFilter: const ColorFilter.mode(K.ink, BlendMode.srcIn),
  );
}

class Back extends StatelessWidget {
  const Back({
    super.key,
    this.tooltip = 'Назад',
    this.icon = Icons.arrow_back_ios_new_rounded,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    icon: Icon(icon, size: 22, color: K.ink),
    onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
  );
}

class Sheet extends StatelessWidget {
  const Sheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = K.sheet,
    this.ring,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color? ring;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: ring == null ? null : Border.all(color: ring!, width: 2),
    ),
    child: child,
  );
}

class RuleLine extends StatelessWidget {
  const RuleLine(this.text, {super.key, this.caveat = false});

  final String text;
  final bool caveat;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        caveat ? Icons.info_outline_rounded : Icons.check_rounded,
        size: 18,
        color: caveat ? K.ink2 : K.pitchText,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: body(13, color: caveat ? K.ink2 : K.ink)),
      ),
    ],
  );
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = 56, this.ring = false});

  final String name;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: K.pitch,
        shape: BoxShape.circle,
        boxShadow: ring
            ? const [
                BoxShadow(color: K.sheet, spreadRadius: 2),
                BoxShadow(color: K.ink, spreadRadius: 4),
              ]
            : null,
      ),
      child: ExcludeSemantics(
        child: Text(initials, style: body(size * 0.38, weight: 600)),
      ),
    );
  }
}
