import 'package:flutter/material.dart';
import 'package:apoio_app/ui/core/theme/interaction_colors.dart';

class LocationPill extends StatelessWidget {
  final bool captured;
  final bool busy;
  final VoidCallback onLocate;

  const LocationPill({
    super.key,
    required this.captured,
    required this.busy,
    required this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = busy
        ? 'Obtendo localização…'
        : captured
            ? 'Atualizar localização'
            : 'Usar minha localização';
    final foreground = captured ? colors.onPrimary : colors.onSurface;

    return Tooltip(
        message: label,
        child: Material(
            color: captured ? colors.primary : colors.surface,
            elevation: 4,
            shadowColor: Colors.black26,
            shape: StadiumBorder(
                side: BorderSide(
                    color: captured ? colors.primary : colors.outline)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                overlayColor: InteractionColors.overlay(dark: captured),
                key: const ValueKey('location-control'),
                onTap: busy ? null : onLocate,
                customBorder: const StadiumBorder(),
                child: AnimatedSize(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 420),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                        height: 48,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox.square(
                              dimension: 48,
                              child: Center(
                                  child: busy
                                      ? SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: foreground))
                                      : Icon(Icons.my_location,
                                          size: 20, color: foreground))),
                          if (!captured)
                            Flexible(
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 20),
                                    child: Text(label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge!
                                            .copyWith(color: foreground)))),
                        ]))))));
  }
}
