import 'package:flutter/material.dart';
import 'interaction_colors.dart';

ThemeData wireframeTheme() {
  const ink = Color(0xff292929);
  const outline = Color(0xffd0d0d0);
  const shape = StadiumBorder();
  final theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.white,
    hoverColor: const Color(0x08292929),
    focusColor: const Color(0x08292929),
    highlightColor: const Color(0x08292929),
    splashColor: const Color(0x08292929),
    colorScheme: const ColorScheme.light(
      primary: ink,
      onPrimary: Colors.white,
      secondary: ink,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xff222222),
      onSurfaceVariant: Color(0xff4b4b4b),
      outline: outline,
      surfaceContainerHighest: InteractionColors.subtle,
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
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ink),
      shape: Border(bottom: BorderSide(color: outline)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          borderSide: BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          borderSide: BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          borderSide: BorderSide(color: ink, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: Colors.white,
                side: const BorderSide(color: ink),
                elevation: 0,
                shape: shape,
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12))
            .copyWith(overlayColor: InteractionColors.overlay(dark: true))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ink,
                side: const BorderSide(color: outline),
                shape: shape,
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12))
            .copyWith(overlayColor: InteractionColors.overlay())),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ink, shape: shape)
            .copyWith(overlayColor: InteractionColors.overlay())),
    iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(overlayColor: InteractionColors.overlay())),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
      shape: const WidgetStatePropertyAll(shape),
      overlayColor: InteractionColors.overlay(),
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      side: const WidgetStatePropertyAll(BorderSide(color: outline)),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? ink : Colors.white),
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : ink),
    )),
    dividerTheme: const DividerThemeData(color: outline, thickness: 1),
    checkboxTheme: CheckboxThemeData(
        side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
            color: states.contains(WidgetState.selected) ? ink : outline))),
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: Color(0xffeeeeee),
        selectionHandleColor: ink),
  );
  return theme.copyWith(
      textTheme: theme.textTheme
          .copyWith(
            headlineSmall: const TextStyle(
                fontSize: 20,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: ink),
            titleLarge: const TextStyle(
                fontSize: 20,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: ink),
            titleMedium: const TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: ink),
            bodyLarge: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: ink),
            bodyMedium: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: ink),
            bodySmall: const TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Color(0xff4b4b4b)),
            labelLarge: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: ink),
            labelMedium: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: ink),
            titleSmall: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: ink),
          )
          .apply(fontFamily: 'Poppins'));
}
