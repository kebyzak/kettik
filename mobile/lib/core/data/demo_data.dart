import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';

const demoMe = Player(id: 'me', name: 'Ерлан Абенов');
const demoEmail = 'erlan@kettik.kz';

const _names = [
  'Азамат',
  'Ерлан',
  'Данияр',
  'Арман',
  'Нурлан',
  'Санжар',
  'Дима',
  'Алибек',
  'Руслан',
  'Ержан',
  'Максат',
  'Олжас',
  'Тимур',
  'Бекзат',
  'Канат',
  'Асхат',
];

List<Place> _paid(int count, {int from = 0}) => [
  for (var i = 0; i < count; i++)
    PaidPlace(
      Player(id: 'p${from + i}', name: _names[(from + i) % _names.length]),
    ),
];

List<Place> _free(int count) => List.filled(count, const FreePlace());

const alem = Venue(name: 'Манеж Alem', address: 'Сығанақ 18');
const nis = Venue(name: 'NIS Mangilik Arena', address: 'Түркістан 32/4а');
const jastar = Venue(name: 'Поле Jastar', address: 'Мәңгілік Ел 37');
const spartak = Venue(name: 'Spartak Indoor', address: 'Кенесары 40');

final demoStart = DateTime(2026, 11, 25, 19, 40);

List<Game> demoGames() {
  DateTime d(int day, int h, [int m = 0]) => DateTime(2026, 11, day, h, m);
  return [
    Game(
      id: 'alem-25',
      venue: alem,
      start: d(25, 22),
      end: d(25, 23, 30),
      rent: const Tenge(45600),
      level: Level.casual,
      organizerId: 'p20',
      createdAt: d(25, 9),
      places: [..._paid(11, from: 20), ..._free(1)],
    ),
    Game(
      id: 'nis-25',
      venue: nis,
      start: d(25, 22, 30),
      end: d(26, 0),
      rent: const Tenge(49500),
      teams: 3,
      level: Level.casual,
      organizerId: 'p0',
      createdAt: d(25, 9, 14),
      places: [
        ..._paid(12),
        HeldPlace(const Player(id: 'p12', name: 'Тимур'), d(25, 19, 44)),
        ..._free(2),
      ],
    ),
    Game(
      id: 'jastar-25',
      venue: jastar,
      start: d(25, 23),
      end: d(26, 0),
      rent: const Tenge(45000),
      level: Level.casual,
      organizerId: 'p30',
      createdAt: d(25, 10),
      places: [..._paid(4, from: 30), ..._free(6)],
    ),
    Game(
      id: 'spartak-26',
      venue: spartak,
      start: d(26, 7),
      end: d(26, 8),
      rent: const Tenge(39000),
      level: Level.casual,
      organizerId: 'p40',
      createdAt: d(25, 10),
      places: [..._paid(2, from: 40), const PaidPlace(demoMe), ..._free(7)],
    ),
    Game(
      id: 'alem-26',
      venue: alem,
      start: d(26, 19, 30),
      end: d(26, 21),
      rent: const Tenge(49600),
      level: Level.middle,
      organizerId: 'p50',
      createdAt: d(25, 12),
      places: [..._paid(6, from: 50), ..._free(10)],
    ),
    Game(
      id: 'spartak-25',
      venue: spartak,
      start: d(25, 21, 30),
      end: d(25, 22, 30),
      rent: const Tenge(40000),
      level: Level.casual,
      organizerId: 'p60',
      createdAt: d(24, 18),
      status: GameStatus.confirmed,
      places: [
        ..._paid(3, from: 60),
        const PaidPlace(demoMe),
        ..._paid(6, from: 63),
      ],
    ),
    Game(
      id: 'jastar-23',
      venue: jastar,
      start: d(23, 21),
      end: d(23, 22),
      rent: const Tenge(45000),
      level: Level.casual,
      organizerId: 'p70',
      createdAt: d(23, 9),
      status: GameStatus.expired,
      places: [
        ..._paid(1, from: 70),
        const PaidPlace(demoMe),
        ..._paid(7, from: 71),
        ..._free(1),
      ],
    ),
  ];
}
