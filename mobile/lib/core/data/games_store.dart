import 'package:flutter/foundation.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';

class GamesStore extends ChangeNotifier {
  GamesStore(List<Game> games) : _games = {for (final g in games) g.id: g};

  final Map<String, Game> _games;
  var _created = 0;

  Game game(String id, DateTime now) => _games[id]!.at(now);

  List<Game> games(DateTime now) =>
      [for (final g in _games.values) g.at(now)]
        ..sort((a, b) => a.start.compareTo(b.start));

  List<(Game, int)> myHolds(Player? me, DateTime now) => [
    if (me != null)
      for (final g in games(now))
        if (g.numberOf(me) case final n? when g.placeAt(n) is HeldPlace) (g, n),
  ];

  void hold(String id, int number, Player me, DateTime now) =>
      _write(id, _games[id]!.hold(number, me, now));

  void pay(String id, int number, DateTime now) =>
      _write(id, _games[id]!.pay(number, now));

  void release(String id, int number) =>
      _write(id, _games[id]!.release(number));

  void leave(String id, int number, DateTime now) =>
      _write(id, _games[id]!.leave(number, now));

  void stay(String id, int number) => _write(id, _games[id]!.stay(number));

  String create({
    required Player organizer,
    required Venue venue,
    required DateTime start,
    required DateTime end,
    required Tenge rent,
    required int size,
    required int teams,
    required Level level,
    required DateTime now,
  }) {
    final id = 'new-${++_created}';
    final game = Game(
      id: id,
      venue: venue,
      start: start,
      end: end,
      rent: rent,
      teams: teams,
      level: level,
      organizerId: organizer.id,
      createdAt: now,
      places: List.filled(size, const FreePlace()),
    );
    _games[id] = game.hold(1, organizer, now);
    notifyListeners();
    return id;
  }

  void _write(String id, Game game) {
    if (identical(_games[id], game)) return;
    _games[id] = game;
    notifyListeners();
  }
}
