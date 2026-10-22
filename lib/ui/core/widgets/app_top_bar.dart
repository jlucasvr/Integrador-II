import 'package:flutter/material.dart';
import 'package:apoio_app/ui/core/theme/interaction_colors.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? sectionTitle;
  final VoidCallback? onManagement;
  final VoidCallback? onBack;
  final bool navigationEnabled;
  final bool managementActive;
  final Widget? action;

  const AppTopBar(
      {super.key,
      this.sectionTitle,
      this.onManagement,
      this.onBack,
      this.navigationEnabled = true,
      this.managementActive = false,
      this.action});

  @override
  Size get preferredSize =>
      Size.fromHeight(76 + (sectionTitle == null ? 0 : 28));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showBack = onBack != null || Navigator.of(context).canPop();
    ButtonStyle circleStyle({bool active = false}) => IconButton.styleFrom(
            fixedSize: const Size.square(48),
            minimumSize: const Size.square(48),
            foregroundColor: active ? colors.onPrimary : colors.onSurface,
            disabledForegroundColor: active ? colors.onPrimary : colors.outline,
            backgroundColor: active ? colors.primary : colors.surface,
            elevation: 3,
            shadowColor: Colors.black26,
            shape: CircleBorder(
                side: BorderSide(
                    color: active ? colors.primary : colors.outline)))
        .copyWith(overlayColor: InteractionColors.overlay(dark: active));

    return DecoratedBox(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xf2ffffff), Color(0x00ffffff)],
                stops: [0, .55, 1])),
        child: SafeArea(
            bottom: false,
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                if (showBack) ...[
                                  IconButton(
                                      tooltip: 'Voltar',
                                      icon: const Icon(Icons.arrow_back_rounded,
                                          size: 20),
                                      style: circleStyle(),
                                      onPressed: navigationEnabled
                                          ? onBack ??
                                              () => Navigator.of(context)
                                                  .maybePop()
                                          : null),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Material(
                                            color: colors.surface,
                                            elevation: 3,
                                            shadowColor: Colors.black26,
                                            shape: StadiumBorder(
                                                side: BorderSide(
                                                    color: colors.outline)),
                                            child: SizedBox(
                                                height: 48,
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 18),
                                                    child: Center(
                                                        widthFactor: 1,
                                                        child: FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                                'Plataforma de apoio',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .labelLarge!
                                                                    .copyWith(
                                                                        fontWeight: FontWeight.w700))))))))),
                                const SizedBox(width: 8),
                                IconButton(
                                    tooltip: 'Gestão',
                                    icon: const Icon(Icons.apartment_rounded,
                                        size: 20),
                                    style:
                                        circleStyle(active: managementActive),
                                    onPressed:
                                        navigationEnabled && !managementActive
                                            ? onManagement
                                            : null),
                                if (action != null) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(height: 48, child: action!),
                                ],
                              ]),
                              if (sectionTitle != null) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                    height: 20,
                                    child: Text(sectionTitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall)),
                              ],
                            ]))))));
  }
}
