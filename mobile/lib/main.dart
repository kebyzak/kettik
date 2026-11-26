import 'package:flutter/material.dart';

import 'package:kettik/app/app.dart';
import 'package:kettik/core/data/demo_data.dart';
import 'package:kettik/core/data/games_store.dart';

void main() {
  final started = Stopwatch()..start();
  runApp(
    KettikApp(
      store: GamesStore(demoGames(), me: demoMe),
      now: () => demoStart.add(started.elapsed),
    ),
  );
}
