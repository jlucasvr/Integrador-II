import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Measures each row before equalizing its cards, without fixed heights or
/// intrinsic measurements (cards may contain LayoutBuilder and wrapped text).
class AdaptiveCardGrid extends StatelessWidget {
  const AdaptiveCardGrid({
    super.key,
    required this.children,
    this.minimumCardWidth = 336,
    this.maximumColumns = 3,
    this.spacing = 24,
  });
  final List<Widget> children;
  final double minimumCardWidth;
  final int maximumColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = math.max(
        1.0,
        MediaQuery.textScalerOf(context).scale(14) / 14,
      );
      final columns =
          ((constraints.maxWidth + spacing) /
                  (minimumCardWidth * scale + spacing))
              .floor()
              .clamp(1, maximumColumns);
      return _CardGrid(columns: columns, spacing: spacing, children: children);
    },
  );
}

class _CardGrid extends MultiChildRenderObjectWidget {
  const _CardGrid({
    required this.columns,
    required this.spacing,
    required super.children,
  });
  final int columns;
  final double spacing;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCardGrid(columns, spacing);
  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderCardGrid).update(columns, spacing);
  }
}

class _GridParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderCardGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GridParentData> {
  _RenderCardGrid(this._columns, this._spacing);
  int _columns;
  double _spacing;
  void update(int columns, double spacing) {
    if (columns == _columns && spacing == _spacing) return;
    _columns = columns;
    _spacing = spacing;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GridParentData) {
      child.parentData = _GridParentData();
    }
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final cardWidth = (width - (_columns - 1) * _spacing) / _columns;
    var child = firstChild;
    var top = 0.0;
    while (child != null) {
      final row = <RenderBox>[];
      var height = 0.0;
      for (var column = 0; column < _columns && child != null; column++) {
        child.layout(
          BoxConstraints.tightFor(width: cardWidth),
          parentUsesSize: true,
        );
        height = math.max(height, child.size.height);
        row.add(child);
        child = childAfter(child);
      }
      for (var column = 0; column < row.length; column++) {
        final cell = row[column];
        cell.layout(
          BoxConstraints.tightFor(width: cardWidth, height: height),
          parentUsesSize: true,
        );
        (cell.parentData! as _GridParentData).offset = Offset(
          column * (cardWidth + _spacing),
          top,
        );
      }
      top += height + (child == null ? 0 : _spacing);
    }
    size = constraints.constrain(Size(width, top));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
