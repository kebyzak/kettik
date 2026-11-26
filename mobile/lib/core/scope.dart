import 'package:flutter/material.dart';

import 'package:kettik/core/data/games_store.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.now,
    required super.child,
  });

  final GamesStore store;
  final DateTime Function() now;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) => old.store != store || old.now != now;
}

Future<void> open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

void landOn(BuildContext context, Widget screen) {
  final nav = Navigator.of(context);
  nav.popUntil((r) => r.isFirst);
  nav.push(MaterialPageRoute<void>(builder: (_) => screen));
}
