extension type const Tenge(int value) {
  Tenge operator +(Tenge other) => Tenge(value + other.value);
}

List<Tenge> splitRent(Tenge rent, int places) {
  if (places <= 0) {
    throw ArgumentError.value(places, 'places', 'must be positive');
  }
  final base = rent.value ~/ places;
  final remainder = rent.value % places;
  return List.generate(places, (i) => Tenge(base + (i < remainder ? 1 : 0)));
}

String formatTenge(Tenge amount) {
  final digits = amount.value.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(' ');
    grouped.write(digits[i]);
  }
  return '$grouped ₸';
}
