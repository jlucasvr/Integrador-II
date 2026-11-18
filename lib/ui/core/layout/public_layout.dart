import 'package:flutter/widgets.dart';

abstract final class PublicLayout {
  static const tabletBreakpoint = 760.0;
  static const desktopBreakpoint = 1024.0;
  static const maximumWidth = 1200.0;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static double pageWidth(BuildContext context, {double compactWidth = 620}) =>
      isDesktop(context) ? maximumWidth : compactWidth;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static double contentWidth(BuildContext context) =>
      isExpanded(context) ? maximumWidth : 620;

  static bool hasOrganizationSidebar(BuildContext context) =>
      isDesktop(context) && MediaQuery.textScalerOf(context).scale(14) <= 21;
}
