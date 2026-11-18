import 'package:apoio_app/ui/core/widgets/action_glow.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/core/widgets/navigation_surface.dart';
import 'package:apoio_app/ui/search/view_models/location_view_model.dart';
import 'package:apoio_app/ui/search/widgets/location_pill.dart';
import 'package:flutter/material.dart';
import 'package:apoio_app/ui/core/theme/interaction_colors.dart';

/// Keeps the floating location control and search pill outside page scrolling.
class SearchDock extends StatelessWidget {
  static const placeholder = 'Buscar item ou categoria';
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final LocationViewModel location;
  final VoidCallback onSearch;
  final VoidCallback? onLocate;
  final Widget? controls;
  final bool actionEnabled;
  final bool highlightLocation;
  final bool highlightAction;
  final IconData actionIcon;
  final String actionLabel;
  final ValueChanged<String>? onChanged;
  final Key? locationKey;
  final double maxWidth;

  const SearchDock({
    super.key,
    required this.formKey,
    required this.controller,
    required this.location,
    required this.onSearch,
    required this.onLocate,
    this.controls,
    this.actionEnabled = true,
    this.highlightLocation = false,
    this.highlightAction = false,
    this.actionIcon = Icons.search,
    this.actionLabel = 'Buscar pontos de atendimento',
    this.onChanged,
    this.locationKey,
    this.maxWidth = 620,
  });

  @override
  Widget build(BuildContext context) {
    final coordinates = location.coordinates;
    final colors = Theme.of(context).colorScheme;
    final locate = onLocate;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: locate != null ? 60 : 0,
            child: const NavigationSurface(
              bottom: true,
              child: SizedBox.expand(),
            ),
          ),
          SafeArea(
            top: false,
            child: Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controls != null) ...[
                        controls!,
                        const SizedBox(height: 12),
                      ],
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (locate != null) const SizedBox(height: 48),
                              SizedBox(
                                height: locate != null
                                    ? AppTopBar.actionGap
                                    : 4,
                              ),
                              if (location.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      location.error!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ),
                              Form(
                                key: formKey,
                                child: Material(
                                  color: colors.surface,
                                  elevation: 3,
                                  shadowColor: Colors.black26,
                                  borderRadius: BorderRadius.circular(32),
                                  child: TextFormField(
                                    key: const ValueKey('search-term'),
                                    controller: controller,
                                    textAlignVertical: TextAlignVertical.center,
                                    onChanged: onChanged,
                                    textInputAction:
                                        actionIcon ==
                                            Icons.arrow_forward_rounded
                                        ? TextInputAction.next
                                        : TextInputAction.search,
                                    maxLength: 100,
                                    decoration: InputDecoration(
                                      hintText: placeholder,
                                      // Keep an accessible name without a floating label.
                                      labelText: 'Item ou categoria',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      fillColor: WidgetStateColor.resolveWith(
                                        (states) =>
                                            states.contains(WidgetState.focused)
                                            ? colors.surface
                                            : InteractionColors.subtle,
                                      ),
                                      hoverColor: Colors.transparent,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(32),
                                        borderSide: BorderSide(
                                          color: colors.primary,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(32),
                                        borderSide: BorderSide(
                                          color: colors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 18,
                                          ),
                                      counterText: '',
                                      suffixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 60,
                                            minHeight: 60,
                                          ),
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Center(
                                          widthFactor: 1,
                                          heightFactor: 1,
                                          child: ActionGlow(
                                            active:
                                                highlightAction &&
                                                actionEnabled &&
                                                !location.busy,
                                            child: IconButton.filled(
                                              key: const ValueKey(
                                                'search-submit',
                                              ),
                                              tooltip: actionLabel,
                                              onPressed:
                                                  location.busy ||
                                                      !actionEnabled
                                                  ? null
                                                  : onSearch,
                                              style:
                                                  IconButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor:
                                                        colors.primary,
                                                    disabledForegroundColor:
                                                        colors.onSurfaceVariant,
                                                    disabledBackgroundColor:
                                                        colors.outline,
                                                    minimumSize:
                                                        const Size.square(48),
                                                    shape: const CircleBorder(
                                                      side: BorderSide.none,
                                                    ),
                                                  ).copyWith(
                                                    overlayColor:
                                                        InteractionColors.overlay(
                                                          dark: true,
                                                        ),
                                                  ),
                                              icon: Icon(actionIcon),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    onFieldSubmitted: (_) {
                                      if (!location.busy && actionEnabled) {
                                        onSearch();
                                      }
                                    },
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Informe um item ou categoria.'
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Visibility(
                                visible: coordinates != null,
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: Text(
                                  '${coordinates?.latitude.toStringAsFixed(6) ?? '-00.000000'}, ${coordinates?.longitude.toStringAsFixed(6) ?? '-00.000000'}',
                                  key: const ValueKey('search-coordinates'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall!
                                      .copyWith(fontSize: 11, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          if (locate != null)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: SizedBox(
                                height: 48,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      key: const ValueKey('location-anchor'),
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: LocationPill(
                                          key: locationKey,
                                          highlight: highlightLocation,
                                          captured: coordinates != null,
                                          busy: location.busy,
                                          onLocate: locate,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
