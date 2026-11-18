import 'package:flutter/material.dart';
import 'public_layout.dart';

class PageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;
  final double? contentMaxWidth;
  const PageBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth,
    this.contentMaxWidth,
  });
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? PublicLayout.pageWidth(context),
      ),
      child: Padding(
        padding: padding,
        child: contentMaxWidth == null
            ? child
            : Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth!),
                  child: child,
                ),
              ),
      ),
    ),
  );
}
