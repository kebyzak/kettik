import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/core/ui/words.dart';
import 'package:kettik/features/auth/sign_in.dart';
import 'package:kettik/features/booking/hold_banner.dart';
import 'package:kettik/features/game/game_screen.dart';
import 'package:kettik/features/ticket/ticket_screen.dart';
import 'package:kettik/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.store,
      builder: (context, _) => EverySecond(
        builder: (context) {
          final now = scope.now();
          final me = scope.me;
          if (me == null) return const _SignedOut();
          final mine = [
            for (final g in scope.store.games(now))
              if (g.numberOf(me) != null) g,
          ];
          bool past(Game g) =>
              g.end.isBefore(now) ||
              g.status == GameStatus.expired ||
              g.status == GameStatus.cancelled;
          final soon = mine
              .where((g) => !past(g) && g.placeAt(g.numberOf(me)!) is PaidPlace)
              .toList();
          final done = mine.where(past).toList().reversed.toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Row(
                children: [
                  Avatar(me.name),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.name, style: display(22)),
                        Text(context.l10n.city, style: body(13, color: K.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(context.l10n.myGames, style: display(15)),
              ),
              for (final (g, n) in scope.store.myHolds(scope.me, now)) ...[
                HoldBanner(game: g, number: n, now: now),
                const SizedBox(height: 8),
              ],
              if (soon.isNotEmpty) _Group(context.l10n.upcoming),
              for (final g in soon) _MyGame(game: g, now: now),
              if (done.isNotEmpty) _Group(context.l10n.past),
              for (final g in done) _MyGame(game: g, now: now),
              if (mine.isEmpty)
                Text(context.l10n.myGamesEmpty, style: body(15, color: K.ink2)),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(context.l10n.account, style: display(15)),
              ),
              Sheet(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Setting(
                      context.l10n.language,
                      context.l10n.languageName,
                      onTap: () => _pickLanguage(context, scope.locale),
                    ),
                    const Divider(height: 1, color: K.line),
                    _Setting(
                      context.l10n.notifications,
                      context.l10n.notificationsOn,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PillButton(
                context.l10n.signOut,
                style: PillStyle.quiet,
                height: 48,
                onPressed: scope.session.signOut,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(title, style: display(13, weight: 500, color: K.ink2)),
  );
}

class _MyGame extends StatelessWidget {
  const _MyGame({required this.game, required this.now});

  final Game game;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final me = AppScope.of(context).me;
    final number = game.numberOf(me)!;
    final over =
        game.end.isBefore(now) ||
        game.status != GameStatus.funding &&
            game.status != GameStatus.confirmed;
    final (
      status,
      color,
    ) = game.end.isBefore(now) && game.status == GameStatus.confirmed
        ? (context.l10n.played(game.paidCount), K.ink2)
        : game.status == GameStatus.funding
        ? (
            context.l10n.collectingUntil(
              game.paidCount,
              game.size,
              hm(game.deadline),
            ),
            K.ink2,
          )
        : statusWords(context.l10n, game);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: over ? K.sheet.withValues(alpha: 0.6) : K.sheet,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => open(
            context,
            game.status == GameStatus.confirmed && !over
                ? TicketScreen(gameId: game.id)
                : GameScreen(gameId: game.id),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.venue.name,
                        style: body(15, weight: 600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${shortDay(context.l10n, game.start)} · ${hm(game.start)} · ${context.l10n.placeNumber(number)}',
                        style: body(13, color: K.ink2),
                      ),
                      Text(status, style: body(13, weight: 600, color: color)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                DotStrip(kindsOf(game, me), size: 9, faded: over, maxWidth: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _pickLanguage(BuildContext context, ValueNotifier<Locale?> locale) {
  final current = context.l10n.localeName;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: K.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.language, style: display(22)),
            const SizedBox(height: 8),
            for (final l in appLocales)
              _Setting(
                lookupAppLocalizations(l).languageName,
                l.languageCode == current ? '✓' : '',
                onTap: () {
                  locale.value = l;
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _Setting extends StatelessWidget {
  const _Setting(this.label, this.value, {this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value, style: body(15, color: K.ink2)),
          ],
        ),
      ),
    ),
  );
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
    children: [
      Text(context.l10n.tabProfile, style: display(22)),
      const SizedBox(height: 8),
      Text(context.l10n.signedOutLead, style: body(15, color: K.ink2)),
      const SizedBox(height: 24),
      PillButton(context.l10n.signInEmail, onPressed: () => signIn(context)),
    ],
  );
}
