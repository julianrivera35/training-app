import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy    = Color(0xFF1B2F5B);
  static const Color blue    = Color(0xFF1565C0);
  static const Color orange  = Color(0xFFE65100);
  static const Color green   = Color(0xFF2E7D32);
  static const Color purple  = Color(0xFF6A1B9A);
  static const Color red     = Color(0xFFB71C1C);
  static const Color teal    = Color(0xFF00695C);
  static const Color amber   = Color(0xFFF57F17);
  static const Color lblue   = Color(0xFF0277BD);
  static const Color bg      = Color(0xFFF4F6FB);

  static const Map<String, Color> _cat = {
    'FUERZA':       blue,
    'POTENCIA':     purple,
    'REHAB':        orange,
    'TENDÓN':       red,
    'TENDON':       red,
    'NATACIÓN':     lblue,
    'NATACION':     lblue,
    'MOVILIDAD':    green,
    'GIRO':         amber,
    'VELOCIDAD':    teal,
    'FLEXIBILIDAD': Color(0xFF4527A0),
    'NÚCLEO':       Color(0xFF00838F),
    'NUCLEO':       Color(0xFF00838F),
    'GLÚTEOS':      Color(0xFF880E4F),
    'GLUTEOS':      Color(0xFF880E4F),
    'PREHAB':       Color(0xFF4E342E),
    'ISOMÉTRICO':   Color(0xFF37474F),
    'ISOMETRICO':   Color(0xFF37474F),
    'RECUPERACIÓN': Color(0xFF1B5E20),
    'RECUPERACION': Color(0xFF1B5E20),
  };

  static Color catColor(String bloque) {
    final up = bloque.toUpperCase();
    for (final e in _cat.entries) {
      if (up.contains(e.key)) return e.value;
    }
    return navy;
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: blue,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: navy,
      unselectedItemColor: Color(0xFF9E9E9E),
      type: BottomNavigationBarType.fixed,
      elevation: 16,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        elevation: 2,
      ),
    ),
  );
}
