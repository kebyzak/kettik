import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/pitch_view.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/features/ticket/ticket_screen.dart';
import 'package:kettik/core/ui/words.dart';

class ConfirmedScreen extends StatefulWidget {
  const ConfirmedScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<ConfirmedScreen> createState() => _ConfirmedScreenState();
}

class _ConfirmedScreenState extends State<ConfirmedScreen>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.disableAnimationsOf(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final g = scope.store.game(widget.gameId, scope.now());
    final me = scope.me;
    double pop(int i) => Curves.easeOutBack.transform(
      ((_c.value * 1600 - 200 - i * 60) / 320).clamp(0.0, 1.0),
    );
    final textIn = Curves.easeOut.transform(
      ((_c.value * 1600 - 1100) / 400).clamp(0.0, 1.0),
    );
    return Scaffold(
      backgroundColor: K.pitch,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                children: [
                  Text(
                    '${shortDay(context.l10n, g.start)} · ${hm(g.start)}',
                    style: body(15, weight: 600),
                  ),
                  const Spacer(),
                  Transform.translate(
                    offset: const Offset(12, 0),
                    child: Back(
                      tooltip: context.l10n.close,
                      icon: Icons.close_rounded,
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ),
                ],
              ),
              PitchView(kinds: kindsOf(g, me), grass: false, spotScale: pop),
              Opacity(
                opacity: textIn,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - textIn)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.confirmedSquad(g.paidCount, g.size),
                        style: display(13),
                      ),
                      const SizedBox(height: 8),
                      Text(context.l10n.statusConfirmed, style: display(34)),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.confirmedLead(g.venue.name, hm(g.start)),
                        style: body(15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: PillButton(
          context.l10n.openTicket,
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => TicketScreen(gameId: widget.gameId),
            ),
          ),
        ),
      ),
    );
  }
}
