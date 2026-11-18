import 'package:flutter/material.dart';
import 'package:apoio_app/ui/core/theme/floating_navigation_style.dart';
import 'package:apoio_app/ui/core/layout/public_layout.dart';
import 'navigation_surface.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  static const actionGap = 16.0;
  final String? sectionTitle;
  final bool showManagement;
  final VoidCallback? onManagement;
  final VoidCallback? onBack;
  final bool navigationEnabled;
  final bool managementActive;
  final bool showLogo;
  final Widget? action;
  final double? maxWidth;

  const AppTopBar({
    super.key,
    this.sectionTitle,
    this.showManagement = true,
    this.onManagement,
    this.onBack,
    this.navigationEnabled = true,
    this.managementActive = false,
    this.showLogo = false,
    this.maxWidth,
    this.action,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showBack = onBack != null || Navigator.of(context).canPop();
    final brandPadding = EdgeInsets.symmetric(horizontal: showLogo ? 14 : 18);
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          Image.asset(
            'assets/brand/apoio-mark.png',
            width: 32,
            height: 32,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          sectionTitle ?? 'Plataforma de apoio',
          style: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
    ButtonStyle circleStyle({bool active = false}) =>
        floatingNavigationStyle(context, active: active, circular: true);

    return NavigationSurface(
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? PublicLayout.pageWidth(context),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showBack) ...[
                        IconButton(
                          tooltip: 'Voltar',
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          style: circleStyle(),
                          onPressed: navigationEnabled
                              ? onBack ?? () => Navigator.of(context).maybePop()
                              : null,
                        ),
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
                              side: BorderSide(color: colors.outline),
                            ),
                            child: SizedBox(
                              height: 48,
                              child: Padding(
                                padding: brandPadding,
                                child: Center(
                                  widthFactor: 1,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: brand,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (showManagement)
                        IconButton(
                          tooltip: 'Gestão',
                          icon: const Icon(Icons.apartment_rounded, size: 20),
                          style: circleStyle(active: managementActive),
                          onPressed: navigationEnabled && !managementActive
                              ? onManagement
                              : null,
                        ),
                      if (action != null) ...[
                        const SizedBox(width: 8),
                        TextButtonTheme(
                          data: TextButtonThemeData(
                            style: floatingNavigationStyle(context),
                          ),
                          child: SizedBox(height: 48, child: action!),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
