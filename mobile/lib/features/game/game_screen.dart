import 'package:flutter/material.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/pitch_view.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/core/ui/words.dart';
import 'package:kettik/features/booking/hold_screen.dart';
import 'package:kettik/features/ticket/ticket_screen.dart';

/// One game: the pitch, the lineup under it, the conditions and one action.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.gameId});
  final String gameId;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? _selected;

  void _take(int number) {
    final scope = AppScope.of(context);
    try {
      scope.store.hold(widget.gameId, number, scope.now());
    } on BookingRejected catch (e) {
      _explain(e.reason);
      return;
    }
    open(context, HoldScreen(gameId: widget.gameId, number: number));
  }

  void _explain(Rejection reason) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: K.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Не получилось занять место', style: display(22)),
          const SizedBox(height: 8),
          Text(rejectionText(reason), style: body(15, color: K.ink2)),
          const SizedBox(height: 20),
          PillButton('Выбрать другое место', onPressed: () => Navigator.of(sheet).pop()),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.store,
      builder: (context, _) => EverySecond(
        builder: (context) {
          final now = scope.now();
          final me = scope.store.me;
          final g = scope.store.game(widget.gameId, now);
          final kinds = kindsOf(g, me);
          final (status, statusColor) = statusWords(g);
          return Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    children: [
                      Transform.translate(offset: const Offset(-12, 0), child: const Back()),
                      const Spacer(),
                      Text(status, style: body(13, weight: 600, color: statusColor)),
                    ],
                  ),
                  Text(g.venue.name, style: display(22)),
                  const SizedBox(height: 4),
                  Text(
                    '${longDate(g.start)} · ${timeRange(g.start, g.end)} · ${g.venue.address}',
                    style: body(15, color: K.ink2),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: K.verge,
                      child: PitchView(
                        kinds: kinds,
                        selected: _selected,
                        overlay: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${g.paidCount}', style: display(28)),
                                  TextSpan(
                                    text: '/${g.size}',
                                    style: display(28, weight: 500, color: K.ink2),
                                  ),
                                ],
                              ),
                            ),
                            Text('оплатили', style: body(13, color: K.ink2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${g.format} · ${g.level.toLowerCase()}', style: body(13, color: K.ink2)),
                  const SizedBox(height: 16),
                  Sheet(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('Состав', style: display(13, weight: 500, color: K.ink2)),
                        ),
                        _Lineup(
                          game: g,
                          me: me,
                          now: now,
                          selected: _selected,
                          onSelect: (n) => setState(() => _selected = _selected == n ? null : n),
                          onTake: _take,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RuleLine(refundPromise(g, g.shareOf(g.numberOf(me) ?? g.size))),
                  const SizedBox(height: 8),
                  const RuleLine(noRefundAfterConfirm, caveat: true),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _action(context, g, me),
            ),
          );
        },
      ),
    );
  }

  Widget _action(BuildContext context, Game g, Player me) {
    final mine = g.numberOf(me);
    if (mine != null && g.placeAt(mine) is HeldPlace) {
      return PillButton(
        'Оплатить место №$mine · ${formatTenge(g.shareOf(mine))}',
        onPressed: () => open(context, HoldScreen(gameId: g.id, number: mine)),
      );
    }
    if (mine != null && g.status == GameStatus.confirmed) {
      return PillButton('Открыть билет', onPressed: () => open(context, TicketScreen(gameId: g.id)));
    }
    if (mine != null) return PillButton('Вы в составе · №$mine', onPressed: null, style: PillStyle.outline);
    final free = g.places.indexWhere((p) => p is FreePlace) + 1;
    if (g.status == GameStatus.funding && free > 0) {
      return PillButton('Занять №$free · ${formatTenge(g.shareOf(free))}', onPressed: () => _take(free));
    }
    return PillButton(g.status == GameStatus.funding ? 'Все места держат' : statusWords(g).$1, onPressed: null);
  }
}

/// Two columns, numbers matching the spots. Tapping a player lights their spot;
/// tapping a free place takes it.
class _Lineup extends StatelessWidget {
  const _Lineup({
    required this.game,
    required this.me,
    required this.now,
    required this.selected,
    required this.onSelect,
    required this.onTake,
  });
  final Game game;
  final Player me;
  final DateTime now;
  final int? selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onTake;

  @override
  Widget build(BuildContext context) {
    final half = (game.size / 2).ceil();
    Widget column(int from, int to) => Expanded(child: Column(children: [for (var n = from; n <= to; n++) _row(n)]));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [column(1, half), const SizedBox(width: 12), column(half + 1, game.size)],
    );
  }

  Widget _row(int n) {
    final place = game.placeAt(n);
    final kind = kindOf(place, me);
    final (name, meta, metaColor) = switch (place) {
      FreePlace() => ('занять', '', K.ink2),
      HeldPlace(:final player, :final until) => (
        player.id == me.id ? 'Вы' : player.name,
        countdown(until.difference(now)),
        K.signal,
      ),
      PaidPlace(:final player) => (
        player.id == me.id ? 'Вы' : player.name,
        player.id == game.organizerId ? 'собирает' : '',
        K.ink2,
      ),
    };
    final free = place is FreePlace;
    return Material(
      color: selected == n ? K.chalk : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => free ? onTake(n) : onSelect(n),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              PlaceChip(n, kind),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: body(15, weight: free ? 600 : 400, color: free ? K.pitchText : K.ink),
                ),
              ),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  style: (meta.contains(':') ? display(11, weight: 600) : body(11)).copyWith(color: metaColor),
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
