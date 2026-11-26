import 'package:flutter/material.dart';

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
                        Text('Астана', style: body(13, color: K.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text('Мои игры', style: display(15)),
              ),
              for (final (g, n) in scope.store.myHolds(scope.me, now)) ...[
                HoldBanner(game: g, number: n, now: now),
                const SizedBox(height: 8),
              ],
              if (soon.isNotEmpty) const _Group('Скоро'),
              for (final g in soon) _MyGame(game: g, now: now),
              if (done.isNotEmpty) const _Group('Прошедшие'),
              for (final g in done) _MyGame(game: g, now: now),
              if (mine.isEmpty)
                Text(
                  'Здесь появятся игры, в которых у вас есть место.',
                  style: body(15, color: K.ink2),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text('Аккаунт', style: display(15)),
              ),
              Sheet(
                padding: EdgeInsets.zero,
                child: Column(
                  children: const [
                    _Setting('Язык', 'Русский'),
                    Divider(height: 1, color: K.line),
                    _Setting('Уведомления', 'Включены'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PillButton(
                'Выйти',
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
        ? ('Сыграно · ${game.paidCount} игроков', K.ink2)
        : game.status == GameStatus.funding
        ? (
            '${game.paidCount}/${game.size} · сбор до ${hm(game.deadline)}',
            K.ink2,
          )
        : statusWords(game);
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
                        '${shortDay(game.start)} · ${hm(game.start)} · место №$number',
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

class _Setting extends StatelessWidget {
  const _Setting(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
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
  );
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
    children: [
      Text('Профиль', style: display(22)),
      const SizedBox(height: 8),
      Text(
        'Войдите, чтобы занимать места, собирать игры и видеть их здесь. Смотреть игры можно и без входа.',
        style: body(15, color: K.ink2),
      ),
      const SizedBox(height: 24),
      PillButton('Войти по почте', onPressed: () => signIn(context)),
    ],
  );
}
