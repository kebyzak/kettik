import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kettik/core/data/api.dart';
import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';

/// The pitch a new game is booked on.
typedef Pitch = ({String fieldId, Venue venue, Tenge hourly});

/// Games from the server. The server decides every rule; between refreshes
/// [Game.at] runs the same clock rules so countdowns stay live.
class GamesStore extends ChangeNotifier {
  GamesStore(this._api);

  final Api _api;
  final Map<String, Game> _games = {};
  var _feed = <String>{};
  var _mine = <String>{};
  Timer? _poll;

  Game game(String id, DateTime now) => _games[id]!.at(now);

  /// The feed and the player's own games.
  List<Game> games(DateTime now) => [
    for (final id in {..._feed, ..._mine}) _games[id]!.at(now),
  ]..sort((a, b) => a.start.compareTo(b.start));

  List<(Game, int)> myHolds(Player? me, DateTime now) => [
    if (me != null)
      for (final g in games(now))
        if (g.numberOf(me) case final n? when g.placeAt(n) is HeldPlace) (g, n),
  ];

  // shortcut: polling every 15 s; move to a WebSocket per room when rooms get busy.
  void watch() {
    _poll ??= Timer.periodic(const Duration(seconds: 15), (_) => refresh());
    refresh();
  }

  /// Reloads the feed, and the player's games when signed in.
  Future<void> refresh() async {
    try {
      final feed = await _api.get('/games') as List<Object?>;
      final mine = _api.token == null
          ? const <Object?>[]
          : await _api.get('/me/games') as List<Object?>;
      _feed = {for (final g in feed) _keep(g)};
      _mine = {for (final g in mine) _keep(g)};
      notifyListeners();
    } on ApiError {
      return; // offline: keep what we have and try on the next tick
    }
  }

  Future<void> hold(String id, int number) =>
      _act(() => _api.post('/games/$id/places/$number/hold'));

  // shortcut: the dev server marks the attempt paid; open the provider's payment page once Halyk ePay is wired.
  Future<void> pay(String id, int number) => _act(() async {
    final attempt = await _api.post(
      '/games/$id/places/$number/pay',
    ) as Map<String, Object?>;
    await _api.post('/dev/payments/${attempt['id']}/succeed');
    return _api.get('/games/$id');
  });

  Future<void> release(String id, int number) =>
      _act(() => _api.delete('/games/$id/places/$number/hold'));

  Future<void> leave(String id, int number) =>
      _act(() => _api.post('/games/$id/places/$number/leave'));

  Future<void> stay(String id, int number) =>
      _act(() => _api.post('/games/$id/places/$number/stay'));

  Future<String> create({
    required String fieldId,
    required DateTime start,
    required DateTime end,
    required int size,
    required int teams,
    required Level level,
  }) async {
    late String id;
    await _act(() async {
      final g = await _api.post('/games', {
        'fieldId': fieldId,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'size': size,
        'teams': teams,
        'level': level.name,
      });
      id = (g as Map<String, Object?>)['id'] as String;
      return g;
    });
    return id;
  }

  // shortcut: the first field of the first venue, as the create screen offers one pitch.
  Future<Pitch> pitch() => _call(() async {
    final venues = await _api.get('/venues') as List<Object?>;
    final v = venues.first as Map<String, Object?>;
    final f = (v['fields'] as List<Object?>).first as Map<String, Object?>;
    return (
      fieldId: f['id'] as String,
      venue: Venue(name: v['name'] as String, address: v['address'] as String),
      hourly: Tenge(f['pricePerHour'] as int),
    );
  });

  Future<List<(DateTime, DateTime)>> busy(
    String fieldId,
    DateTime from,
    DateTime to,
  ) => _call(() async {
    final q =
        'from=${Uri.encodeQueryComponent(from.toUtc().toIso8601String())}'
        '&to=${Uri.encodeQueryComponent(to.toUtc().toIso8601String())}';
    final list = await _api.get('/fields/$fieldId/busy?$q') as List<Object?>;
    return [
      for (final s in list.cast<Map<String, Object?>>())
        (_time(s['start']), _time(s['end'])),
    ];
  });

  Future<void> _act(Future<Object?> Function() request) => _call(() async {
    final g = await request();
    _keep(g);
    _mine.add((g as Map<String, Object?>)['id'] as String);
    notifyListeners();
  });

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiError catch (e) {
      throw BookingRejected(_rejections[e.reason] ?? Rejection.failed);
    }
  }

  String _keep(Object? json) {
    final g = _game(json as Map<String, Object?>);
    _games[g.id] = g;
    return g.id;
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}

const _rejections = {
  'place_taken': Rejection.placeTaken,
  'already_in_game': Rejection.alreadyInGame,
  'funding_closed': Rejection.fundingClosed,
  'hold_expired': Rejection.holdExpired,
  'not_held': Rejection.notHeld,
  'cannot_leave': Rejection.cannotLeave,
  'slot_taken': Rejection.slotTaken,
  'too_late': Rejection.tooLate,
  'offline': Rejection.offline,
};

DateTime _time(Object? s) => DateTime.parse(s as String).toLocal();

Player? _player(Object? json) => switch (json) {
  {'id': final String id, 'name': final String name} => Player(
    id: id,
    name: name,
  ),
  _ => null,
};

Game _game(Map<String, Object?> j) {
  final venue = j['venue'] as Map<String, Object?>;
  return Game(
    id: j['id'] as String,
    venue: Venue(
      name: venue['name'] as String,
      address: venue['address'] as String,
    ),
    start: _time(j['start']),
    end: _time(j['end']),
    rent: Tenge(j['rent'] as int),
    teams: j['teams'] as int,
    level: Level.values.byName(j['level'] as String),
    organizerId: j['organizerId'] as String,
    createdAt: _time(j['createdAt']),
    status: GameStatus.values.byName(j['status'] as String),
    places: [
      for (final p
          in (j['places'] as List<Object?>).cast<Map<String, Object?>>())
        switch (p['state']) {
          'held' => HeldPlace(
            _player(p['player'])!,
            _time(p['until']),
            replacing: _player(p['replacing']),
          ),
          'paid' => PaidPlace(
            _player(p['player'])!,
            leaving: p['leaving'] as bool,
          ),
          _ => const FreePlace(),
        },
    ],
  );
}
