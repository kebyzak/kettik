import 'package:flutter_test/flutter_test.dart';
import 'package:kettik/domain/game.dart';
import 'package:kettik/domain/money.dart';

const azamat = Player(id: 'p1', name: 'Азамат');
const erlan = Player(id: 'p2', name: 'Ерлан');
const me = Player(id: 'me', name: 'Ерлан А.');

Game twoPlaceGame({required DateTime createdAt, required DateTime start}) => Game(
      id: 'g1',
      venue: const Venue(name: 'NIS Mangilik Arena', address: 'Түркістан 32/4а'),
      start: start,
      end: start.add(const Duration(minutes: 90)),
      rent: const Tenge(9001),
      format: '1×1',
      level: 'Любители',
      organizerId: azamat.id,
      createdAt: createdAt,
      places: const [PaidPlace(azamat), FreePlace()],
    );

void main() {
  group('splitRent', () {
    test('divides evenly when it can', () {
      expect(splitRent(const Tenge(49500), 15), List.filled(15, const Tenge(3300)));
    });

    test('gives the remainder one tenge at a time to the first places', () {
      expect(splitRent(const Tenge(100), 3), const [Tenge(34), Tenge(33), Tenge(33)]);
      expect(splitRent(const Tenge(9001), 2), const [Tenge(4501), Tenge(4500)]);
    });

    test('shares always add up to the rent', () {
      final shares = splitRent(const Tenge(33000), 7);
      expect(shares.fold<int>(0, (sum, t) => sum + t.value), 33000);
    });

    test('rejects a game without places', () {
      expect(() => splitRent(const Tenge(100), 0), throwsArgumentError);
    });
  });

  group('formatTenge', () {
    test('groups thousands with non-breaking spaces', () {
      expect(formatTenge(const Tenge(49500)), '49 500 ₸');
      expect(formatTenge(const Tenge(1234567)), '1 234 567 ₸');
      expect(formatTenge(const Tenge(900)), '900 ₸');
    });
  });

  group('fundingDeadline', () {
    test('is two hours before the game when that comes first', () {
      expect(fundingDeadline(createdAt: DateTime(2026, 11, 25, 9, 14), start: DateTime(2026, 11, 25, 22, 30)),
          DateTime(2026, 11, 25, 20, 30));
    });

    test('is 24 hours after creation when that comes first', () {
      expect(fundingDeadline(createdAt: DateTime(2026, 11, 25, 10), start: DateTime(2026, 11, 27, 20)),
          DateTime(2026, 11, 26, 10));
    });
  });

  group('taking and paying a place', () {
    final created = DateTime(2026, 11, 25, 9);
    final start = DateTime(2026, 11, 25, 22, 30); // deadline 20:30
    final game = twoPlaceGame(createdAt: created, start: start);

    test('holding a free place reserves it for ten minutes', () {
      final now = DateTime(2026, 11, 25, 19, 40);
      final held = game.hold(2, me, now);
      final place = held.placeAt(2);
      expect(place, isA<HeldPlace>());
      expect((place as HeldPlace).until, DateTime(2026, 11, 25, 19, 50));
    });

    test('a hold never outlives the funding deadline', () {
      final held = game.hold(2, me, DateTime(2026, 11, 25, 20, 25));
      expect((held.placeAt(2) as HeldPlace).until, DateTime(2026, 11, 25, 20, 30));
    });

    test('a taken place cannot be held', () {
      expect(() => game.hold(1, me, DateTime(2026, 11, 25, 19)),
          throwsA(isA<BookingRejected>().having((e) => e.reason, 'reason', Rejection.placeTaken)));
    });

    test('one player holds at most one place', () {
      expect(() => game.hold(2, azamat, DateTime(2026, 11, 25, 19)),
          throwsA(isA<BookingRejected>().having((e) => e.reason, 'reason', Rejection.alreadyInGame)));
    });

    test('no holds once funding has closed', () {
      expect(() => game.hold(2, me, DateTime(2026, 11, 25, 20, 30)),
          throwsA(isA<BookingRejected>().having((e) => e.reason, 'reason', Rejection.fundingClosed)));
    });

    test('the last payment confirms the game', () {
      final now = DateTime(2026, 11, 25, 19, 40);
      final paid = game.hold(2, me, now).pay(2, now.add(const Duration(minutes: 3)));
      expect(paid.placeAt(2), isA<PaidPlace>());
      expect(paid.status, GameStatus.confirmed);
    });

    test('paying after the hold expired does not restore the place', () {
      final now = DateTime(2026, 11, 25, 19, 40);
      final held = game.hold(2, me, now);
      expect(() => held.pay(2, now.add(const Duration(minutes: 11))),
          throwsA(isA<BookingRejected>().having((e) => e.reason, 'reason', Rejection.holdExpired)));
    });

    test('paying twice changes nothing', () {
      final now = DateTime(2026, 11, 25, 19, 40);
      final once = game.hold(2, me, now).pay(2, now);
      expect(once.pay(2, now), same(once));
    });

    test('an expired hold frees the place', () {
      final held = game.hold(2, me, DateTime(2026, 11, 25, 19, 40));
      expect(held.at(DateTime(2026, 11, 25, 19, 51)).placeAt(2), isA<FreePlace>());
    });

    test('an unfilled game expires at the deadline', () {
      expect(game.at(DateTime(2026, 11, 25, 20, 30)).status, GameStatus.expired);
      expect(game.at(DateTime(2026, 11, 25, 20, 29)).status, GameStatus.funding);
    });

    test('the share of a place comes from the fixed rent', () {
      expect(game.shareOf(1), const Tenge(4501));
      expect(game.shareOf(2), const Tenge(4500));
    });
  });
}
