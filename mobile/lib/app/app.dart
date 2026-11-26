import 'package:flutter/material.dart';

import 'package:kettik/core/data/games_store.dart';
import 'package:kettik/core/data/session.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/features/create/create_screen.dart';
import 'package:kettik/features/feed/feed_screen.dart';
import 'package:kettik/features/profile/profile_screen.dart';

class KettikApp extends StatelessWidget {
  const KettikApp({
    super.key,
    required this.store,
    required this.session,
    required this.now,
  });

  final GamesStore store;
  final Session session;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      return AppScope(
        store: store,
        session: session,
        me: session.me,
        now: now,
        child: MaterialApp(
          title: 'kettik',
          debugShowCheckedModeBanner: false,
          theme: kettikTheme(),
          home: const Shell(),
        ),
      );
    },
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final me = AppScope.of(context).me;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: const [FeedScreen(), ProfileScreen()],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: K.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _Tab(
                  label: 'Игры',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                  icon: const _PitchGlyph(),
                ),
                _Tab(
                  label: 'Собрать',
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateScreen(),
                    ),
                  ),
                  icon: Container(
                    width: 48,
                    height: 32,
                    decoration: BoxDecoration(
                      color: K.ink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: K.sheet,
                      size: 20,
                    ),
                  ),
                ),
                _Tab(
                  label: 'Профиль',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                  icon: me == null
                      ? const Icon(
                          Icons.person_outline_rounded,
                          size: 26,
                          color: K.ink,
                        )
                      : Avatar(me.name, size: 26, ring: _tab == 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: body(11, weight: 600, color: selected ? K.ink : K.ink2),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PitchGlyph extends StatelessWidget {
  const _PitchGlyph();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 24,
    height: 24,
    child: CustomPaint(painter: _GlyphPainter()),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = K.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(s.width * .12, s.height * .62)
        ..lineTo(s.width * .5, s.height * .8)
        ..lineTo(s.width * .88, s.height * .54)
        ..lineTo(s.width * .5, s.height * .36)
        ..close(),
      p,
    );
    canvas.drawLine(
      Offset(s.width * .31, s.height * .71),
      Offset(s.width * .69, s.height * .45),
      p,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => false;
}
