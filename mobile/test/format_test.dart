import 'package:flutter_test/flutter_test.dart';
import 'package:kettik/ui/format.dart';

void main() {
  test('places left uses the right Russian plural', () {
    expect([1, 2, 4, 5, 11, 12, 14, 21, 22, 25].map(placesLeft), [
      '1 место', '2 места', '4 места', '5 мест', '11 мест',
      '12 мест', '14 мест', '21 место', '22 места', '25 мест',
    ]);
  });

  test('day titles name today and tomorrow', () {
    final now = DateTime(2026, 11, 25, 19, 40);
    expect(dayTitle(DateTime(2026, 11, 25, 22, 30), now), 'Сегодня, среда');
    expect(dayTitle(DateTime(2026, 11, 26, 7), now), 'Завтра, четверг');
    expect(dayTitle(DateTime(2026, 11, 27, 7), now), 'Пятница, 27 ноября');
  });

  test('countdown never goes below zero', () {
    expect(countdown(const Duration(minutes: 4, seconds: 12)), '04:12');
    expect(countdown(const Duration(seconds: -5)), '00:00');
  });
}
