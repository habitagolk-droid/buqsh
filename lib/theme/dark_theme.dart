import 'package:flutter/material.dart';

ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Cairo',
  primaryColor: const Color(0xFF278D5B),
  secondaryHeaderColor: const Color(0xFFD4E157),
  brightness: Brightness.dark,
  shadowColor: Colors.black.withOpacity(0.4),
  scaffoldBackgroundColor: const Color(0xFF101816),
  cardColor: const Color(0xFF1A2E2A),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Color(0xFF8dbac3),
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      color: Color(0xFFF3F4F6),
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: Color(0xFFF3F4F6),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: Color(0xFFF3F4F6),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      color: Color(0xFFD1D5DB),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodySmall: TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.black),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1A2E2A),
    selectedItemColor: Color(0xFFD4E157),
    unselectedItemColor: Color(0xFF9CA3AF),
    type: BottomNavigationBarType.fixed,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1A2E2A),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF48635B)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF48635B)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD4E157), width: 1.5),
    ),
  ),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    background: const Color(0xFF101816),
    onBackground: const Color(0xFFC3CAD9),
    primary: const Color(0xFF278D5B),
    onPrimary: Colors.white,
    secondary: const Color(0xFFD4E157),
    onSecondary: const Color(0xFF101816),
    error: Colors.redAccent,
    onError: Colors.redAccent,
    surface: const Color(0xFF1A2E2A),
    onSurface: Colors.white70,
    shadow: Colors.black.withOpacity(0.4),
  ),
);
