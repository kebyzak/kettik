import 'package:intl/intl.dart';

import 'package:kettik/l10n/app_localizations.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String hm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String timeRange(DateTime start, DateTime end) => '${hm(start)}–${hm(end)}';

String countdown(Duration left) {
  final s = left.isNegative ? 0 : left.inSeconds;
  return '${_two(s ~/ 60)}:${_two(s % 60)}';
}

String _capital(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String weekdayShort(AppLocalizations l, DateTime d) =>
    _capital(DateFormat.E(l.localeName).format(d));

String _weekday(AppLocalizations l, DateTime d) =>
    DateFormat.EEEE(l.localeName).format(d);

String shortDay(AppLocalizations l, DateTime d) =>
    '${weekdayShort(l, d)} ${d.day}';

String longDate(AppLocalizations l, DateTime d) =>
    '${_capital(_weekday(l, d))}, ${DateFormat.MMMMd(l.localeName).format(d)}';

String dayWord(AppLocalizations l, DateTime d, DateTime now) {
  if (sameDay(d, now)) return l.today;
  if (sameDay(d, now.add(const Duration(days: 1)))) return l.tomorrow;
  return _capital(_weekday(l, d));
}

String dayTitle(AppLocalizations l, DateTime d, DateTime now) {
  final word = dayWord(l, d, now);
  return word == l.today || word == l.tomorrow
      ? '$word, ${_weekday(l, d)}'
      : longDate(l, d);
}
