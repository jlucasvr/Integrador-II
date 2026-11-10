import 'package:flutter/material.dart';

class OperationHeading extends StatelessWidget {
  const OperationHeading({
    super.key,
    required this.title,
    required this.description,
    this.actions = const [],
  });

  final String title, description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      const SizedBox(height: 4),
      Text(description),
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    ],
  );
}

class OperationStatus extends StatelessWidget {
  const OperationStatus(this.label, this.icon, {super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 6),
      Flexible(child: Text(label)),
    ],
  );
}

class OperationFilterChip extends StatelessWidget {
  const OperationFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ChoiceChip(
      shape: const StadiumBorder(),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurface,
      ),
      selected: selected,
      selectedColor: colors.primary,
      checkmarkColor: colors.onPrimary,
      onSelected: (_) => onSelect(),
    );
  }
}

/// Rows share column widths without putting the entire dataset in one widget.
class OperationColumns extends StatelessWidget {
  const OperationColumns({
    super.key,
    required this.widths,
    required this.cells,
    this.heading = false,
  });

  final List<int> widths;
  final List<Widget> cells;
  final bool heading;

  @override
  Widget build(BuildContext context) {
    assert(widths.length == cells.length);
    final theme = Theme.of(context);
    return ColoredBox(
      color: heading
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                for (var i = 0; i < cells.length; i++)
                  Expanded(
                    flex: widths[i],
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == cells.length - 1 ? 0 : 12,
                      ),
                      child: heading
                          ? Semantics(
                              header: true,
                              child: DefaultTextStyle.merge(
                                style: theme.textTheme.labelMedium,
                                child: cells[i],
                              ),
                            )
                          : cells[i],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class OperationEmpty extends StatelessWidget {
  const OperationEmpty(this.title, this.description, {super.key});

  final String title, description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(description),
      ],
    ),
  );
}
