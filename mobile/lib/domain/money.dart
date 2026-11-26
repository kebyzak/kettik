/// Whole tenge. The first booking scenario prices rent and shares in whole
/// tenge (docs/booking-mvp.md); the API stores minor units and converts at the
/// boundary.
extension type const Tenge(int value) {
  Tenge operator +(Tenge other) => Tenge(value + other.value);
}

/// Splits [rent] across [places]. The remainder goes one tenge at a time to the
/// first places, so the shares always add up to exactly the rent.
List<Tenge> splitRent(Tenge rent, int places) {
  if (places <= 0) throw ArgumentError.value(places, 'places', 'must be positive');
  final base = rent.value ~/ places;
  final remainder = rent.value % places;
  return List.generate(places, (i) => Tenge(base + (i < remainder ? 1 : 0)));
}

/// `49 500 ₸` with non-breaking spaces so a price never wraps.
String formatTenge(Tenge amount) {
  final digits = amount.value.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(' ');
    grouped.write(digits[i]);
  }
  return '$grouped ₸';
}
