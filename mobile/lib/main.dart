import 'package:material_ui/material_ui.dart';

import 'package:kettik/app/app.dart';
import 'package:kettik/core/data/demo_data.dart';
import 'package:kettik/core/data/games_store.dart';
import 'package:kettik/core/data/session.dart';

void main() {
  final started = Stopwatch()..start();
  runApp(
    KettikApp(
      store: GamesStore(demoGames()),
      session: Session(accounts: {demoEmail: demoMe}),
      now: () => demoStart.add(started.elapsed),
      locale: ValueNotifier(null),
    ),
  );
}
