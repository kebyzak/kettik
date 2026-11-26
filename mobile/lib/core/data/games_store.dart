import 'package:flutter/foundation.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';

class GamesStore extends ChangeNotifier {
  GamesStore(List<Game> games, {required this.me})
    : _games = {for (final g in games) g.id: g};

  final Player me;
  final Map<String, Game> _games;
  var _created = 0;

  Game game(String id, DateTime now) => _games[id]!.at(now);

  List<Game> games(DateTime now) =>
      [for (final g in _games.values) g.at(now)]
        ..sort((a, b) => a.start.compareTo(b.start));

  List<(Game, int)> myHolds(DateTime now) => [
    for (final g in games(now))
      if (g.numberOf(me) case final n? when g.placeAt(n) is HeldPlace) (g, n),
  ];

  void hold(String id, int number, DateTime now) =>
      _write(id, _games[id]!.hold(number, me, now));

  void pay(String id, int number, DateTime now) =>
      _write(id, _games[id]!.pay(number, now));

  void release(String id, int number) =>
      _write(id, _games[id]!.release(number));

  String create({
    required Venue venue,
    required DateTime start,
    required DateTime end,
    required Tenge rent,
    required int size,
    required String format,
    required String level,
    required DateTime now,
  }) {
    final id = 'new-${++_created}';
    final game = Game(
      id: id,
      venue: venue,
      start: start,
      end: end,
      rent: rent,
      format: format,
      level: level,
      organizerId: me.id,
      createdAt: now,
      places: List.filled(size, const FreePlace()),
    );
    _games[id] = game.hold(1, me, now);
    notifyListeners();
    return id;
  }

  void _write(String id, Game game) {
    if (identical(_games[id], game)) return;
    _games[id] = game;
    notifyListeners();
  }
}
