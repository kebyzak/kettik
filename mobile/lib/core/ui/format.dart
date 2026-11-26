String _two(int n) => n.toString().padLeft(2, '0');

String hm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String timeRange(DateTime start, DateTime end) => '${hm(start)}–${hm(end)}';

String countdown(Duration left) {
  final s = left.isNegative ? 0 : left.inSeconds;
  return '${_two(s ~/ 60)}:${_two(s % 60)}';
}

const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const _weekdaysLong = [
  'понедельник',
  'вторник',
  'среда',
  'четверг',
  'пятница',
  'суббота',
  'воскресенье',
];
const _months = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

String shortDay(DateTime d) => '${weekdayShort(d)} ${d.day}';

String longDate(DateTime d) {
  final wd = _weekdaysLong[d.weekday - 1];
  return '${wd[0].toUpperCase()}${wd.substring(1)}, ${d.day} ${_months[d.month - 1]}';
}

String dayTitle(DateTime d, DateTime now) {
  final wd = _weekdaysLong[d.weekday - 1];
  if (sameDay(d, now)) return 'Сегодня, $wd';
  if (sameDay(d, now.add(const Duration(days: 1)))) return 'Завтра, $wd';
  return longDate(d);
}

String placesLeft(int n) {
  final mod10 = n % 10, mod100 = n % 100;
  final word = mod10 == 1 && mod100 != 11
      ? 'место'
      : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
      ? 'места'
      : 'мест';
  return '$n $word';
}
