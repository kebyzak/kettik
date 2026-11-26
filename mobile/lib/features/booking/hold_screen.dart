import 'package:flutter/material.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/pitch_view.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/core/ui/words.dart';
import 'package:kettik/features/booking/confirmed_screen.dart';
import 'package:kettik/features/game/game_screen.dart';

class HoldScreen extends StatelessWidget {
  const HoldScreen({super.key, required this.gameId, required this.number});

  final String gameId;
  final int number;

  void _pay(BuildContext context) {
    final scope = AppScope.of(context);
    try {
      scope.store.pay(gameId, number, scope.now());
    } on BookingRejected {
      return;
    }
    final confirmed =
        scope.store.game(gameId, scope.now()).status == GameStatus.confirmed;
    landOn(
      context,
      confirmed ? ConfirmedScreen(gameId: gameId) : GameScreen(gameId: gameId),
    );
  }

  void _release(BuildContext context) {
    AppScope.of(context).store.release(gameId, number);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.store,
      builder: (context, _) => EverySecond(
        builder: (context) {
          final now = scope.now();
          final me = scope.store.me;
          final g = scope.store.game(gameId, now);
          final place = g.placeAt(number);
          final held = place is HeldPlace && place.player.id == me.id;
          return Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: const Offset(-12, 0),
                      child: const Back(tooltip: 'Назад к игре'),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: K.verge,
                      child: PitchView(
                        kinds: kindsOf(g, me),
                        numbers: false,
                        pulse: held ? number : null,
                        overlay: Text(
                          held
                              ? 'Место №$number за вами'
                              : 'Место освободилось',
                          style: display(22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (held)
                    _Timer(left: place.until.difference(now))
                  else
                    const _Lapsed(),
                  const SizedBox(height: 12),
                  Sheet(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      children: [
                        _Fact('Игра', g.venue.name),
                        _Fact('Когда', '${shortDay(g.start)} · ${hm(g.start)}'),
                        _Fact(
                          'Аренда',
                          '${formatTenge(g.rent)} на ${g.size} мест',
                        ),
                        const Divider(height: 16, color: K.line),
                        Row(
                          children: [
                            Text('Ваша доля', style: body(15, weight: 600)),
                            const Spacer(),
                            Text(
                              formatTenge(g.shareOf(number)),
                              style: display(15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RuleLine(refundPromise(g, g.shareOf(number))),
                  const SizedBox(height: 8),
                  const RuleLine(
                    'Передумаете до подтверждения — деньги вернутся.',
                  ),
                  const SizedBox(height: 8),
                  const RuleLine(noRefundAfterConfirm, caveat: true),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: held
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PillButton(
                          'Оплатить ${formatTenge(g.shareOf(number))}',
                          onPressed: () => _pay(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Картой на защищённой странице банка',
                          style: body(13, color: K.ink2),
                        ),
                        PillButton(
                          'Освободить место',
                          style: PillStyle.quiet,
                          height: 44,
                          onPressed: () => _release(context),
                        ),
                      ],
                    )
                  : PillButton(
                      'Вернуться к игре',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _Timer extends StatelessWidget {
  const _Timer({required this.left});

  final Duration left;

  @override
  Widget build(BuildContext context) {
    final urgent = left < const Duration(minutes: 2);
    final color = urgent ? K.signal : K.ink;
    return Sheet(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Держим, пока вы платите', style: body(15, weight: 600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: left.inSeconds / placeHold.inSeconds,
                    minHeight: 6,
                    color: color,
                    backgroundColor: K.line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            liveRegion: false,
            label: 'Осталось',
            child: Text(countdown(left), style: display(22, color: color)),
          ),
        ],
      ),
    );
  }
}

class _Lapsed extends StatelessWidget {
  const _Lapsed();

  @override
  Widget build(BuildContext context) => Sheet(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Время вышло', style: body(15, weight: 600)),
        const SizedBox(height: 4),
        Text(
          'Если деньги успели списаться, они вернутся автоматически.',
          style: body(13, color: K.ink2),
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label, style: body(15, color: K.ink2)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
