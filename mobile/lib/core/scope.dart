import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/data/games_store.dart';
import 'package:kettik/core/data/session.dart';
import 'package:kettik/core/domain/game.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.session,
    required this.me,
    required this.now,
    required this.locale,
    required super.child,
  });

  final GamesStore store;
  final Session session;
  final Player? me;
  final DateTime Function() now;
  final ValueNotifier<Locale?> locale;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      old.store != store ||
      old.session != session ||
      old.me != me ||
      old.now != now ||
      old.locale != locale;
}

Future<void> open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

void landOn(BuildContext context, Widget screen) {
  final nav = Navigator.of(context);
  nav.popUntil((r) => r.isFirst);
  nav.push(MaterialPageRoute<void>(builder: (_) => screen));
}
