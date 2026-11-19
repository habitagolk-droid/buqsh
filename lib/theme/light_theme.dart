import 'package:flutter/material.dart';
import 'package:six_cash/core/theme/buqsh_design.dart';
import 'package:six_cash/util/color_resources.dart';
ThemeData light = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Cairo',
  primaryColor: BqColors.brand,
  secondaryHeaderColor: BqColors.accent,
  highlightColor: BqColors.brand,
  cardColor: Colors.white,
  scaffoldBackgroundColor: BqColors.bg,
  shadowColor: const Color(0x240C4A40),
  textTheme: const TextTheme(
    titleLarge: TextStyle(color: Color(0xFF003E47), fontSize: 18, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: Color(0xFF10201D), fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Color(0xFF10201D), fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Color(0xFF10201D), fontSize: 14, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(color: Color(0xFF6B7D7D), fontSize: 14, fontWeight: FontWeight.w500),
    bodySmall: TextStyle(color: Color(0xFF6B7D7D), fontSize: 12, fontWeight: FontWeight.w500),
    labelLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(color: Color(0xFF6B7D7D), fontSize: 12, fontWeight: FontWeight.w500),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: BqColors.brand,
    foregroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: BqColors.input,
    hintStyle: const TextStyle(color: BqColors.muted, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: BqColors.brand, width: 1.5),
    ),
  ),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white, selectedItemColor: ColorResources.themeLightBackgroundColor,
  ),
  colorScheme: ColorScheme(
    // background: const Color(0xFFf0f0f0),
    background: const Color(0xFFF8F9FA),
    brightness: Brightness.light,
    primary: const Color(0xFF0C4A40),
    onPrimary: Colors.white,
    secondary: const Color(0xFF278D5B),
    onSecondary: const Color(0xFF0C4A40),
    error: Colors.redAccent,
    onError: Colors.redAccent,
    onBackground: const Color(0xFF6B7D7D),
    surface: Colors.white,
    onSurface:  const Color(0xFF10201D),
    shadow: const Color(0x240C4A40),
  ),

);
