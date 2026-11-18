import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ActionGlow extends StatefulWidget {
  const ActionGlow({super.key, required this.active, required this.child});
  final bool active;
  final Widget child;
  @override
  State<ActionGlow> createState() => _ActionGlowState();
}

class _ActionGlowState extends State<ActionGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..addStatusListener(_onStatus);
  bool _reducedMotion = false;
  bool _looping = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        !_looping &&
        widget.active &&
        !_reducedMotion) {
      _looping = true;
      _glow.repeat(
        min: 0,
        max: 1,
        reverse: true,
        period: const Duration(milliseconds: 1800),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(ActionGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active && !_reducedMotion) {
      if (!_glow.isAnimating) {
        _looping = false;
        _glow.forward(from: 0);
      }
    } else {
      _glow.stop();
      _looping = false;
      _glow.value = widget.active ? .65 : 0;
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !widget.active
      ? widget.child
      : CustomPaint(
          key: const ValueKey('action-glow'),
          painter: _PulsePainter(_glow),
          child: RepaintBoundary(child: widget.child),
        );
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final strength =
        .54 + .42 * Curves.easeInOutSine.transform(animation.value);
    final contour = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(2.5),
      Radius.circular(size.height / 2 + 3),
    );
    canvas.drawRRect(
      contour,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff25d366).withValues(alpha: strength)
        ..strokeWidth = 10 + 6 * strength
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.animation != animation;
}
