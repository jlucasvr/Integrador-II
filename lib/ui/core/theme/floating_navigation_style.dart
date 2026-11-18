import 'package:flutter/material.dart';
import 'package:apoio_app/ui/core/theme/interaction_colors.dart';

ButtonStyle floatingNavigationStyle(
  BuildContext context, {
  bool active = false,
  bool circular = false,
}) {
  final colors = Theme.of(context).colorScheme;
  return TextButton.styleFrom(
    foregroundColor: active ? colors.onPrimary : colors.onSurface,
    disabledForegroundColor: active ? colors.onPrimary : colors.outline,
    backgroundColor: active ? colors.primary : colors.surface,
    disabledBackgroundColor: active ? colors.primary : colors.surface,
    fixedSize: circular ? const Size.square(48) : const Size.fromHeight(48),
    minimumSize: circular ? const Size.square(48) : const Size(0, 48),
    padding: circular
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 18),
    elevation: 3,
    shadowColor: Colors.black26,
    textStyle: Theme.of(
      context,
    ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
    shape: circular ? const CircleBorder() : const StadiumBorder(),
    side: BorderSide(color: active ? colors.primary : colors.outline),
  ).copyWith(overlayColor: InteractionColors.overlay(dark: active));
}
