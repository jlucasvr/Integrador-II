import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/ui/core/theme/interaction_colors.dart';
import 'package:flutter/material.dart';

class IntentSelector extends StatelessWidget {
  final SearchIntent intent;
  final ValueChanged<SearchIntent> onChanged;

  const IntentSelector(
      {super.key, required this.intent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('intent-selector'),
      color: colors.surface,
      shape: StadiumBorder(side: BorderSide(color: colors.primary)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: SearchIntent.values.map((value) {
            final selected = intent == value;
            return Expanded(
              child: Semantics(
                selected: selected,
                child: TextButton(
                  onPressed: () => onChanged(value),
                  style: TextButton.styleFrom(
                    backgroundColor: selected ? colors.primary : colors.surface,
                    foregroundColor:
                        selected ? colors.onPrimary : colors.primary,
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w700),
                  ).copyWith(
                      // Apply the new selection without a lingering transition.
                      animationDuration: Duration.zero,
                      overlayColor: InteractionColors.overlay(dark: selected)),
                  child: Text(value == SearchIntent.help
                      ? 'Preciso de ajuda'
                      : 'Quero doar'),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
