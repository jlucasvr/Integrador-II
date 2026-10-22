import 'package:flutter/material.dart';

/// Keeps the native segmented control, matching each half's border to its fill.
class SelectionBorder extends StadiumBorder {
  final bool selectedFirst;
  final Color selectedColor;

  const SelectionBorder(
      {required this.selectedFirst,
      required this.selectedColor,
      required super.side});

  @override
  SelectionBorder copyWith({BorderSide? side}) => SelectionBorder(
      selectedFirst: selectedFirst,
      selectedColor: selectedColor,
      side: side ?? this.side);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    super.paint(canvas, rect, textDirection: textDirection);
    final onLeft = selectedFirst != (textDirection == TextDirection.rtl);
    final selectedRect = Rect.fromLTRB(onLeft ? rect.left : rect.center.dx,
        rect.top, onLeft ? rect.center.dx : rect.right, rect.bottom);
    canvas.save();
    canvas.clipRect(selectedRect.inflate(side.width));
    StadiumBorder(side: side.copyWith(color: selectedColor))
        .paint(canvas, rect, textDirection: textDirection);
    canvas.restore();
  }
}
