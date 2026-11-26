import 'money.dart';

/// Rules mirror docs/booking-mvp.md. The server is the authority; the client
/// uses the same rules to render state and to run the demo without a backend.
const placeHold = Duration(minutes: 10);
const fundingWindow = Duration(hours: 24);
const fundingCloseBeforeStart = Duration(hours: 2);

/// The earlier of 24 h after creation and 2 h before the game.
DateTime fundingDeadline({required DateTime createdAt, required DateTime start}) {
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

/// One place in a game. Its number is its position in [Game.places] plus one.
sealed class Place {
  const Place();
}

final class FreePlace extends Place {
  const FreePlace();
}

final class HeldPlace extends Place {
  const HeldPlace(this.player, this.until);
  final Player player;
  final DateTime until;
}

final class PaidPlace extends Place {
  const PaidPlace(this.player);
  final Player player;
}

/// Server booking states: HELD → funding, CONFIRMED, EXPIRED, CANCELLED.
enum GameStatus { funding, confirmed, expired, cancelled }

enum Rejection { placeTaken, alreadyInGame, fundingClosed, holdExpired, notHeld }

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
    required this.format,
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
  final String format;
  final String level;
  final String organizerId;
  final DateTime createdAt;
  final List<Place> places;
  final GameStatus status;

  DateTime get deadline => fundingDeadline(createdAt: createdAt, start: start);
  int get size => places.length;
  int get paidCount => places.whereType<PaidPlace>().length;
  int get heldCount => places.whereType<HeldPlace>().length;
  Place placeAt(int number) => places[number - 1];
  Tenge shareOf(int number) => splitRent(rent, size)[number - 1];

  /// The place number [player] holds or has paid for, if any.
  int? numberOf(Player player) {
    for (var i = 0; i < size; i++) {
      final p = places[i];
      if ((p is HeldPlace && p.player.id == player.id) || (p is PaidPlace && p.player.id == player.id)) return i + 1;
    }
    return null;
  }

  /// This game as it stands at [now]: lapsed holds are free, an unfilled game
  /// past its deadline has expired.
  Game at(DateTime now) {
    final current = [
      for (final p in places) p is HeldPlace && !now.isBefore(p.until) ? const FreePlace() : p,
    ];
    final expired = status == GameStatus.funding && !now.isBefore(deadline);
    return _copy(places: current, status: expired ? GameStatus.expired : status);
  }

  Game hold(int number, Player player, DateTime now) {
    final game = at(now);
    if (game.status != GameStatus.funding) throw const BookingRejected(Rejection.fundingClosed);
    if (game.numberOf(player) != null) throw const BookingRejected(Rejection.alreadyInGame);
    if (game.placeAt(number) is! FreePlace) throw const BookingRejected(Rejection.placeTaken);
    final byHold = now.add(placeHold);
    final until = byHold.isBefore(deadline) ? byHold : deadline;
    return game._replace(number, HeldPlace(player, until));
  }

  /// Credits the payment for [number]. Paying an already paid place is a no-op,
  /// so a repeated provider notification changes nothing.
  Game pay(int number, DateTime now) {
    final place = placeAt(number);
    if (place is PaidPlace) return this;
    if (place is! HeldPlace) throw const BookingRejected(Rejection.notHeld);
    if (!now.isBefore(place.until)) throw const BookingRejected(Rejection.holdExpired);
    final paid = _replace(number, PaidPlace(place.player));
    return paid.paidCount == size ? paid._copy(status: GameStatus.confirmed) : paid;
  }

  /// Gives an unpaid hold back before it lapses.
  Game release(int number) => placeAt(number) is HeldPlace ? _replace(number, const FreePlace()) : this;

  Game _replace(int number, Place place) => _copy(places: [...places]..[number - 1] = place);

  Game _copy({List<Place>? places, GameStatus? status}) => Game(
        id: id,
        venue: venue,
        start: start,
        end: end,
        rent: rent,
        format: format,
        level: level,
        organizerId: organizerId,
        createdAt: createdAt,
        places: places ?? this.places,
        status: status ?? this.status,
      );
}
