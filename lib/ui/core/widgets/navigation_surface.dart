import 'package:flutter/material.dart';

/// A single linear fade sized by the navigation's own content.
class NavigationSurface extends StatelessWidget {
  const NavigationSurface({
    super.key,
    required this.child,
    this.bottom = false,
  });

  final Widget child;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: bottom ? Alignment.topCenter : Alignment.bottomCenter,
          end: bottom ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [surface.withValues(alpha: 0), surface],
        ),
      ),
      child: child,
    );
  }
}
