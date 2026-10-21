import 'package:flutter/material.dart';

ThemeData wireframeTheme() {
  const ink = Color(0xff292929);
  const outline = Color(0xff777777);
  const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)));
  final theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Arial',
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: ink,
      onPrimary: Colors.white,
      secondary: ink,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xff222222),
      onSurfaceVariant: Color(0xff4b4b4b),
      outline: outline,
      surfaceContainerHighest: Color(0xffeeeeee),
      surfaceTint: Colors.transparent,
      error: Color(0xff292929),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontFamily: 'Arial',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: ink),
      shape: Border(bottom: BorderSide(color: Color(0xffaaaaaa))),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: ink, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: shape,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ink,
            side: const BorderSide(color: outline),
            shape: shape,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12))),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ink, shape: shape)),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
      shape: const WidgetStatePropertyAll(shape),
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      side: const WidgetStatePropertyAll(BorderSide(color: outline)),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? const Color(0xff333333)
              : Colors.white),
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : ink),
    )),
    dividerTheme:
        const DividerThemeData(color: Color(0xffaaaaaa), thickness: 1),
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: Color(0xffdddddd),
        selectionHandleColor: ink),
  );
  return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
    headlineSmall: const TextStyle(
        fontSize: 20, height: 1.3, fontWeight: FontWeight.bold, color: ink),
    titleLarge: const TextStyle(
        fontSize: 20, height: 1.3, fontWeight: FontWeight.bold, color: ink),
    titleMedium: const TextStyle(
        fontSize: 16, height: 1.4, fontWeight: FontWeight.bold, color: ink),
    bodyMedium: const TextStyle(fontSize: 14, height: 1.5, color: ink),
    bodySmall:
        const TextStyle(fontSize: 12, height: 1.5, color: Color(0xff4b4b4b)),
    labelLarge: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.normal, color: ink),
  ));
}
