import 'package:flutter/material.dart';

/// Colour roles of the «Разметка» system. Green means grass and "paid";
/// white on the pitch is a player; orange is a running hold or deadline.
abstract final class K {
  static const ink = Color(0xFF22302A);
  static const ink2 = Color(0xFF55635B);
  static const chalk = Color(0xFFEDF1E9);
  static const verge = Color(0xFFDCE6D4);
  static const sheet = Color(0xFFFFFFFF);
  static const pitch = Color(0xFF6EA464);
  static const pitchText = Color(0xFF3B7334);
  static const signal = Color(0xFFA8501A);
  static const line = Color(0xFFE3E9DE);
  static const dash = Color(0xFF8A968E);
  static const faded = Color(0xFFB7C2B2);
  static const danger = Color(0xFFB3261E);
}

// The bundled fonts are variable, so the weight is set on the 'wght' axis too.
TextStyle _style(String family, double size, int weight, Color color, double height, bool tabular) => TextStyle(
  fontFamily: family,
  fontSize: size,
  fontWeight: FontWeight.values[weight ~/ 100 - 1],
  fontVariations: [FontVariation('wght', weight.toDouble())],
  fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  color: color,
  height: height,
);

/// Montserrat: numbers, times, prices and headings.
TextStyle display(double size, {int weight = 700, Color color = K.ink}) =>
    _style('Montserrat', size, weight, color, 1.2, true);

/// Onest: everything people read.
TextStyle body(double size, {int weight = 400, Color color = K.ink}) =>
    _style('Onest', size, weight, color, 1.4, false);

ThemeData kettikTheme() => ThemeData(
  scaffoldBackgroundColor: K.chalk,
  fontFamily: 'Onest',
  colorScheme: ColorScheme.fromSeed(seedColor: K.pitch, primary: K.ink, surface: K.chalk),
  textTheme: TextTheme(bodyMedium: body(15)),
  splashFactory: InkSparkle.splashFactory,
);
