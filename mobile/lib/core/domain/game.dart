import 'package:kettik/core/domain/money.dart';

const placeHold = Duration(minutes: 10);
const fundingWindow = Duration(hours: 24);
const fundingCloseBeforeStart = Duration(hours: 2);
const replaceCloseBeforeStart = Duration(hours: 2);

DateTime fundingDeadline({
  required DateTime createdAt,
  required DateTime start,
}) {
  final byWindow = createdAt.add(fundingWindow);
  final byStart = start.subtract(fundingCloseBeforeStart);
  return byWindow.isBefore(byStart) ? byWindow : byStart;
}

class Player {
  const Player({required this.id, required this.name});

  final String id;
  final String name;
}

class Venue {
  const Venue({required this.name, required this.address});

  final String name;
  final String address;
}

sealed class Place {
  const Place();
}

final class FreePlace extends Place {
  const FreePlace();
}

final class HeldPlace extends Place {
  const HeldPlace(this.player, this.until, {this.replacing});

  final Player player;
  final DateTime until;
  // Set when the hold buys out a confirmed player who is leaving.
  final Player? replacing;
}

final class PaidPlace extends Place {
  const PaidPlace(this.player, {this.leaving = false});

  final Player player;
  // Leaving after confirmation: open to a replacement until replaceDeadline.
  final bool leaving;
}

enum Level { casual, middle, strong }

enum GameStatus { funding, confirmed, expired, cancelled }

enum Rejection {
  placeTaken,
  alreadyInGame,
  fundingClosed,
  holdExpired,
  notHeld,
  cannotLeave,
}

class BookingRejected implements Exception {
  const BookingRejected(this.reason);

  final Rejection reason;

  @override
  String toString() => 'BookingRejected($reason)';
}

class Game {
  const Game({
    required this.id,
    required this.venue,
    required this.start,
    required this.end,
    required this.rent,
    this.teams = 2,
    required this.level,
    required this.organizerId,
    required this.createdAt,
    required this.places,
    this.status = GameStatus.funding,
  });

  final String id;
  final Venue venue;
  final DateTime start;
  final DateTime end;
  final Tenge rent;
  final int teams;
  final Level level;
  final String organizerId;
  final DateTime createdAt;
  final List<Place> places;
  final GameStatus status;

  DateTime get deadline => fundingDeadline(createdAt: createdAt, start: start);

  DateTime get replaceDeadline => start.subtract(replaceCloseBeforeStart);

  bool get seeksReplacement =>
      status == GameStatus.confirmed &&
      places.any((p) => p is PaidPlace && p.leaving);

  int get size => places.length;

  int get paidCount => places.whereType<PaidPlace>().length;

  int get heldCount => places.whereType<HeldPlace>().length;

  Place placeAt(int number) => places[number - 1];

  Tenge shareOf(int number) => splitRent(rent, size)[number - 1];

  int? numberOf(Player? player) {
    if (player == null) return null;
    for (var i = 0; i < size; i++) {
      final p = places[i];
      if ((p is HeldPlace && p.player.id == player.id) ||
          (p is PaidPlace && p.player.id == player.id)) {
        return i + 1;
      }
    }
    return null;
  }

  Game at(DateTime now) {
    final replacing = now.isBefore(replaceDeadline);
    final current = [
      for (final p in places)
        switch (p) {
          HeldPlace(:final until, replacing: final r)
              when !now.isBefore(until) =>
            r == null ? const FreePlace() : PaidPlace(r, leaving: replacing),
          // No replacement in time: the leaver keeps the place and the charge.
          PaidPlace(:final player, leaving: true) when !replacing => PaidPlace(
            player,
          ),
          _ => p,
        },
    ];
    final expired = status == GameStatus.funding && !now.isBefore(deadline);
    return _copy(
      places: current,
      status: expired ? GameStatus.expired : status,
    );
  }

  Game hold(int number, Player player, DateTime now) {
    final game = at(now);
    final confirmed = game.status == GameStatus.confirmed;
    if (game.status != GameStatus.funding && !confirmed) {
      throw const BookingRejected(Rejection.fundingClosed);
    }
    if (game.numberOf(player) != null) {
      throw const BookingRejected(Rejection.alreadyInGame);
    }
    final place = game.placeAt(number);
    final Player? leaver = switch (place) {
      PaidPlace(:final player, leaving: true) when confirmed => player,
      _ => null,
    };
    if (confirmed ? leaver == null : place is! FreePlace) {
      throw const BookingRejected(Rejection.placeTaken);
    }
    final byHold = now.add(placeHold);
    final limit = confirmed ? replaceDeadline : deadline;
    final until = byHold.isBefore(limit) ? byHold : limit;
    return game._replace(number, HeldPlace(player, until, replacing: leaver));
  }

  Game pay(int number, DateTime now) {
    final place = placeAt(number);
    if (place is PaidPlace) return this;
    if (place is! HeldPlace) throw const BookingRejected(Rejection.notHeld);
    if (!now.isBefore(place.until)) {
      throw const BookingRejected(Rejection.holdExpired);
    }
    final paid = _replace(number, PaidPlace(place.player));
    return paid.paidCount == size
        ? paid._copy(status: GameStatus.confirmed)
        : paid;
  }

  Game release(int number) => switch (placeAt(number)) {
    HeldPlace(:final player, replacing: null)
        when player.id == organizerId && status == GameStatus.funding =>
      _copy(status: GameStatus.cancelled),
    HeldPlace(replacing: final r) => _replace(
      number,
      r == null ? const FreePlace() : PaidPlace(r, leaving: true),
    ),
    _ => this,
  };

  // Before confirmation the place is freed and refunded; the organizer leaving
  // cancels the room and refunds everyone. After confirmation the booking
  // stays and the leaver is refunded only if a replacement pays in time.
  Game leave(int number, DateTime now) {
    final game = at(now);
    final place = game.placeAt(number);
    if (place is! PaidPlace) throw const BookingRejected(Rejection.cannotLeave);
    if (game.status == GameStatus.funding) {
      return place.player.id == organizerId
          ? game._copy(status: GameStatus.cancelled)
          : game._replace(number, const FreePlace());
    }
    if (game.status != GameStatus.confirmed ||
        place.leaving ||
        !now.isBefore(replaceDeadline)) {
      throw const BookingRejected(Rejection.cannotLeave);
    }
    return game._replace(number, PaidPlace(place.player, leaving: true));
  }

  Game stay(int number) => switch (placeAt(number)) {
    PaidPlace(:final player, leaving: true) => _replace(
      number,
      PaidPlace(player),
    ),
    _ => this,
  };

  Game _replace(int number, Place place) =>
      _copy(places: [...places]..[number - 1] = place);

  Game _copy({List<Place>? places, GameStatus? status}) => Game(
    id: id,
    venue: venue,
    start: start,
    end: end,
    rent: rent,
    teams: teams,
    level: level,
    organizerId: organizerId,
    createdAt: createdAt,
    places: places ?? this.places,
    status: status ?? this.status,
  );
}
