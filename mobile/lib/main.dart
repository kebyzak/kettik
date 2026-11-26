import 'package:flutter/material.dart';

import 'app.dart';
import 'data/demo_data.dart';
import 'data/games_store.dart';

void main() {
  // shortcut: the demo runs on a clock that starts at the demo's own "now" so the sample games make sense; use DateTime.now once games come from the API.
  final started = Stopwatch()..start();
  runApp(KettikApp(
    store: GamesStore(demoGames(), me: demoMe),
    now: () => demoStart.add(started.elapsed),
  ));
}
