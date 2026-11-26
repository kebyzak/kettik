import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/features/booking/hold_screen.dart';
import 'package:kettik/core/ui/words.dart';

class HoldBanner extends StatelessWidget {
  const HoldBanner({
    super.key,
    required this.game,
    required this.number,
    required this.now,
  });

  final Game game;
  final int number;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final until = (game.placeAt(number) as HeldPlace).until;
    final left = countdown(until.difference(now));
    return Material(
      color: K.sheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: K.signal, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => open(context, HoldScreen(gameId: game.id, number: number)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.bannerHolding(number, left),
                      style: body(13, weight: 600, color: K.signal),
                    ),
                    Text(
                      '${game.venue.name} · ${shortDay(context.l10n, game.start)}, ${hm(game.start)}',
                      style: body(15, weight: 600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: K.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.l10n.pay,
                  style: display(13, weight: 600, color: K.sheet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
