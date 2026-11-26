import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/pitch_view.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/core/ui/words.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.store,
      builder: (context, _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final now = scope.now();
    final me = scope.me;
    final g = scope.store.game(gameId, now);
    final mine = g.numberOf(me);
    final place = mine == null ? null : g.placeAt(mine);
    final leaving = place is PaidPlace && place.leaving;
    final canLeave =
        place is PaidPlace && !leaving && now.isBefore(g.replaceDeadline);
    final untilStart = g.start.difference(now);
    final names = [
      for (final p in g.places)
        if (p case PaidPlace(:final player))
          player.id == me?.id ? context.l10n.youShort : player.name,
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: const Back(),
                ),
                const Spacer(),
                Text(
                  context.l10n.statusConfirmed,
                  style: body(13, weight: 600, color: K.pitchText),
                ),
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
                        kinds: [
                          for (final k in kindsOf(g, me))
                            k == SpotKind.mine ? k : SpotKind.paid,
                        ],
                        grass: false,
                        numbers: false,
                        overlay: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              untilStart.isNegative
                                  ? context.l10n.gameRunning
                                  : context.l10n.startsIn(
                                      dayWord(context.l10n, g.start, now),
                                      untilStart.inHours,
                                      untilStart.inMinutes % 60,
                                    ),
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
                          Text(
                            context.l10n.untilTime(g.venue.address, hm(g.end)),
                            style: body(15, color: K.ink2),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _Cell(
                                context.l10n.cellNumber,
                                mine == null ? '—' : '$mine',
                                big: true,
                              ),
                              _Cell(
                                context.l10n.cellFormat,
                                formatName(context.l10n, g.size, g.teams),
                              ),
                              _Cell(
                                context.l10n.cellPaid,
                                mine == null
                                    ? '—'
                                    : formatTenge(g.shareOf(mine)),
                              ),
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
            Text(
              context.l10n.lineupCount(g.paidCount),
              style: display(13, weight: 500, color: K.ink2),
            ),
            const SizedBox(height: 8),
            Text(names.join(' · '), style: body(15).copyWith(height: 1.7)),
            const SizedBox(height: 24),
            if (leaving) ...[
              RuleLine(
                context.l10n.replaceSearch(
                  hm(g.replaceDeadline),
                  formatTenge(g.shareOf(mine!)),
                ),
              ),
              const SizedBox(height: 12),
              PillButton(
                context.l10n.stayInGame,
                style: PillStyle.outline,
                onPressed: () => scope.store.stay(gameId, mine),
              ),
            ] else if (canLeave) ...[
              RuleLine(refundAfterConfirm(context.l10n, g), caveat: true),
              PillButton(
                context.l10n.cantCome,
                style: PillStyle.quiet,
                height: 44,
                onPressed: () {
                  try {
                    scope.store.leave(gameId, mine!, scope.now());
                  } on BookingRejected {
                    return; // the cutoff passed while the screen was open
                  }
                },
              ),
            ],
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
