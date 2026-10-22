import 'package:apoio_app/ui/search/view_models/location_view_model.dart';
import 'package:apoio_app/ui/search/widgets/location_pill.dart';
import 'package:flutter/material.dart';
import 'package:apoio_app/ui/core/theme/interaction_colors.dart';

/// Keeps the floating location control and search pill outside page scrolling.
class SearchDock extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final LocationViewModel location;
  final VoidCallback onSearch;
  final VoidCallback onLocate;
  final Widget? controls;

  const SearchDock({
    super.key,
    required this.formKey,
    required this.controller,
    required this.location,
    required this.onSearch,
    required this.onLocate,
    this.controls,
  });

  @override
  Widget build(BuildContext context) {
    final coordinates = location.coordinates;
    final colors = Theme.of(context).colorScheme;
    final locationPill = LocationPill(
        captured: coordinates != null, busy: location.busy, onLocate: onLocate);

    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: DecoratedBox(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  Color(0x00ffffff),
                  Color(0xf2ffffff),
                  Colors.white
                ],
                    stops: [
                  0,
                  0.45,
                  1
                ])),
            child: SafeArea(
                top: false,
                child: Align(
                    heightFactor: 1,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
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
                                  SizedBox(
                                      height: 48,
                                      child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            if (coordinates != null)
                                              Positioned(
                                                  left: 60,
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Text(
                                                      '${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}',
                                                      key: const ValueKey(
                                                          'search-coordinates'),
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall)),
                                            Positioned(
                                                key: const ValueKey(
                                                    'location-anchor'),
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: locationPill)),
                                          ])),
                                  const SizedBox(height: 4),
                                  if (location.error != null)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Semantics(
                                            liveRegion: true,
                                            child: Text(location.error!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall))),
                                  Form(
                                      key: formKey,
                                      child: TextFormField(
                                          key: const ValueKey('search-term'),
                                          controller: controller,
                                          textInputAction:
                                              TextInputAction.search,
                                          maxLength: 100,
                                          decoration: InputDecoration(
                                              hintText:
                                                  'Buscar item ou categoria',
                                              // Keep an accessible name without a floating label.
                                              labelText: 'Item ou categoria',
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.never,
                                              fillColor: WidgetStateColor.resolveWith((states) =>
                                                  states.contains(WidgetState.focused)
                                                      ? colors.surface
                                                      : InteractionColors
                                                          .subtle),
                                              hoverColor: Colors.transparent,
                                              enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                  borderSide: BorderSide(
                                                      color: colors.primary)),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                  borderSide: BorderSide(
                                                      color: colors.primary,
                                                      width: 2)),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                              counterText: '',
                                              suffixIconConstraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                                              suffixIcon: Padding(padding: const EdgeInsets.all(6), child: IconButton.filled(key: const ValueKey('search-submit'), tooltip: 'Buscar pontos de atendimento', onPressed: location.busy ? null : onSearch, style: IconButton.styleFrom(foregroundColor: Colors.white, backgroundColor: colors.primary, disabledForegroundColor: Colors.white, minimumSize: const Size.square(48), shape: const CircleBorder(side: BorderSide.none)).copyWith(overlayColor: InteractionColors.overlay(dark: true)), icon: const Icon(Icons.search, color: Colors.white)))),
                                          onFieldSubmitted: (_) {
                                            if (!location.busy) {
                                              onSearch();
                                            }
                                          },
                                          validator: (value) => value == null || value.trim().isEmpty ? 'Informe um item ou categoria.' : null)),
                                ])))))));
  }
}
