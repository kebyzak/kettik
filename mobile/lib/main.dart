import 'package:flutter/material.dart';

import 'package:kettik/app/app.dart';
import 'package:kettik/core/data/demo_data.dart';
import 'package:kettik/core/data/games_store.dart';

void main() {
  // shortcut: the demo runs on a clock that starts at the demo's own "now" so the sample games make sense; use DateTime.now once games come from the API.
  final started = Stopwatch()..start();
  runApp(
    KettikApp(
      store: GamesStore(demoGames(), me: demoMe),
      now: () => demoStart.add(started.elapsed),
    ),
  );
}
