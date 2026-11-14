import 'package:flutter/material.dart';
import 'package:six_cash/util/color_resources.dart';
ThemeData light = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Cairo',
  primaryColor: const Color(0xFF003E47),
  secondaryHeaderColor: const Color(0xFFE0EC53),
  highlightColor: const Color(0xFF003E47),
  cardColor: Colors.white,
  shadowColor: Colors.grey[300],
  textTheme: const TextTheme(
    titleLarge: TextStyle(color: Color(0xFF003E47), fontSize: 18, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: Color(0xFF1A1D20), fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Color(0xFF1A1D20), fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Color(0xFF1A1D20), fontSize: 14, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(color: Color(0xFF4A5568), fontSize: 14, fontWeight: FontWeight.w500),
    bodySmall: TextStyle(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.w500),
    labelLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.w500),
  ),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white, selectedItemColor: ColorResources.themeLightBackgroundColor,
  ),
  colorScheme: ColorScheme(
    // background: const Color(0xFFf0f0f0),
    background: const Color(0xFFfaf7f6),
    brightness: Brightness.light,
    primary: const Color(0xFF003E47),
    onPrimary: const Color(0xFF562E9C),
    secondary: const Color(0xFFE0EC53),
    onSecondary: const Color(0xFFE0EC53),
    error: Colors.redAccent,
    onError: Colors.redAccent,
    onBackground: const Color(0xFFC3CAD9),
    surface: Colors.white,
    onSurface:  const Color(0xFF002349),
    shadow: Colors.grey[300],
  ),

);