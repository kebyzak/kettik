import 'package:flutter/material.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/pitch_view.dart';
import 'package:kettik/core/ui/theme.dart';

/// Game day: when, where, your number, who is coming.
class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key, required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final now = scope.now();
    final me = scope.store.me;
    final g = scope.store.game(gameId, now);
    final mine = g.numberOf(me);
    final untilStart = g.start.difference(now);
    final names = [
      for (final p in g.places)
        if (p case PaidPlace(:final player)) player.id == me.id ? 'вы' : player.name,
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                Transform.translate(offset: const Offset(-12, 0), child: const Back()),
                const Spacer(),
                Text('Игра состоится', style: body(13, weight: 600, color: K.pitchText)),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColoredBox(
                color: K.sheet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ColoredBox(
                      color: K.pitch,
                      child: PitchView(
                        kinds: [for (final k in kindsOf(g, me)) k == SpotKind.mine ? k : SpotKind.paid],
                        grass: false,
                        numbers: false,
                        overlay: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              untilStart.isNegative
                                  ? 'Игра идёт'
                                  : '${dayTitle(g.start, now).split(',').first} · через ${untilStart.inHours} ч ${untilStart.inMinutes % 60} мин',
                              style: body(13, weight: 600),
                            ),
                            Text(hm(g.start), style: display(40)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.venue.name, style: display(15)),
                          Text('${g.venue.address} · до ${hm(g.end)}', style: body(15, color: K.ink2)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _Cell('Номер', mine == null ? '—' : '$mine', big: true),
                              _Cell('Формат', g.format),
                              _Cell('Оплачено', mine == null ? '—' : formatTenge(g.shareOf(mine))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Состав · ${g.paidCount}', style: display(13, weight: 500, color: K.ink2)),
            const SizedBox(height: 8),
            Text(names.join(' · '), style: body(15).copyWith(height: 1.7)),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, {this.big = false});
  final String label;
  final String value;
  final bool big;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: body(13, color: K.ink2)),
        Text(value, style: big ? display(22) : body(15, weight: 600)),
      ],
    ),
  );
}
