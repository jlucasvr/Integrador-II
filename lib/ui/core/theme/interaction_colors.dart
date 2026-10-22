import 'package:flutter/material.dart';

abstract final class InteractionColors {
  static const subtle = Color(0xfff7f7f7);

  static WidgetStateProperty<Color?> overlay({bool dark = false}) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        if (!states.any({
          WidgetState.hovered,
          WidgetState.focused,
          WidgetState.pressed,
        }.contains)) {
          return Colors.transparent;
        }
        return dark || states.contains(WidgetState.selected)
            ? const Color(0x14ffffff)
            : const Color(0x08292929);
      });
}
