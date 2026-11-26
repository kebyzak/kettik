import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/features/booking/hold_banner.dart';
import 'package:kettik/features/create/create_screen.dart';
import 'package:kettik/features/game/game_screen.dart';
import 'package:kettik/core/ui/words.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  var _day = 0;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.store,
      builder: (context, _) => EverySecond(
        builder: (context) {
          final now = scope.now();
          final day = DateTime(
            now.year,
            now.month,
            now.day,
          ).add(Duration(days: _day));
          final games = [
            for (final g in scope.store.games(now))
              if ((g.status == GameStatus.funding || g.seeksReplacement) &&
                  sameDay(g.start, day))
                g,
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  const Wordmark(),
                  const Spacer(),
                  Text(context.l10n.city, style: body(15, weight: 600)),
                ],
              ),
              const SizedBox(height: 16),
              _DayStrip(
                now: now,
                selected: _day,
                onSelect: (i) => setState(() => _day = i),
              ),
              for (final (g, n) in scope.store.myHolds(scope.me, now)) ...[
                const SizedBox(height: 12),
                HoldBanner(game: g, number: n, now: now),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text(
                  dayTitle(context.l10n, day, now),
                  style: display(13, weight: 500, color: K.ink2),
                ),
              ),
              if (games.isEmpty) const _EmptyDay(),
              for (final g in games) ...[
                _GameCard(game: g),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.now,
    required this.selected,
    required this.onSelect,
  });
  final DateTime now;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 7; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: _day(context, DateTime(now.year, now.month, now.day + i), i),
        ),
      ],
    ],
  );

  Widget _day(BuildContext context, DateTime d, int i) {
    final on = i == selected;
    return Semantics(
      selected: on,
      button: true,
      label: longDate(context.l10n, d),
      excludeSemantics: true,
      child: Material(
        color: on ? K.ink : K.sheet,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onSelect(i),
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdayShort(context.l10n, d),
                  style: body(11, weight: 600, color: on ? K.sheet : K.ink),
                ),
                Text(
                  '${d.day}',
                  style: display(15, color: on ? K.sheet : K.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final me = AppScope.of(context).me;
    final free = kindsOf(game, me).where((k) => k == SpotKind.free).length;
    return Material(
      color: K.sheet,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => open(context, GameScreen(gameId: game.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(timeRange(game.start, game.end), style: display(15)),
                    Text(
                      game.venue.name,
                      style: body(15, weight: 600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${game.venue.address} · ${formatName(context.l10n, game.size, game.teams)}',
                      style: body(13, color: K.ink2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: context.l10n.paidOf(game.paidCount, game.size),
                      child: DotStrip(kindsOf(game, me)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatTenge(game.shareOf(game.size)),
                    style: display(13),
                  ),
                  Text(
                    game.seeksReplacement
                        ? context.l10n.feedSeeksReplacement
                        : free == 0
                        ? context.l10n.feedPlacesHeld
                        : context.l10n.placesLeft(free),
                    style: body(
                      13,
                      weight: free <= 2 ? 600 : 400,
                      color: free <= 2 ? K.signal : K.ink2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();
  @override
  Widget build(BuildContext context) => Sheet(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.emptyTitle, style: display(22)),
        const SizedBox(height: 4),
        Text(context.l10n.emptyLead, style: body(15, color: K.ink2)),
        const SizedBox(height: 16),
        PillButton(
          context.l10n.createGame,
          onPressed: () => open(context, const CreateScreen()),
        ),
      ],
    ),
  );
}
