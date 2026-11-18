import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Centers controls below a naturally sized heading and grows to allow scrolling.
class StepLayout extends MultiChildRenderObjectWidget {
  StepLayout({
    super.key,
    required Widget header,
    required Widget content,
    required this.centerContent,
  }) : super(children: [header, content]);
  final bool centerContent;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _StepRenderBox(centerContent);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _StepRenderBox).centerContent = centerContent;
  }
}

class _StepParentData extends ContainerBoxParentData<RenderBox> {}

class _StepRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StepParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StepParentData> {
  _StepRenderBox(this._centerContent);
  bool _centerContent;
  set centerContent(bool value) {
    if (_centerContent == value) return;
    _centerContent = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StepParentData) {
      child.parentData = _StepParentData();
    }
  }

  @override
  void performLayout() {
    final header = firstChild!;
    final content = lastChild!;
    final childConstraints = BoxConstraints.tightFor(
      width: constraints.maxWidth,
    );
    header.layout(childConstraints, parentUsesSize: true);
    content.layout(childConstraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(constraints.maxWidth, header.size.height + content.size.height),
    );
    (header.parentData! as _StepParentData).offset = Offset.zero;
    final freeSpace = size.height - header.size.height - content.size.height;
    (content.parentData! as _StepParentData).offset = Offset(
      0,
      header.size.height +
          (_centerContent && freeSpace > 0 ? freeSpace / 2 : 0),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
