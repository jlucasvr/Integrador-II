import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/ui/search/widgets/intent_selector.dart';
import 'package:apoio_app/ui/search/widgets/category_picker.dart';
import 'package:flutter/material.dart';

class HomeSearchOptions extends StatelessWidget {
  final SearchIntent intent;
  final ValueChanged<SearchIntent> onIntentChanged;
  final ValueChanged<String> onCategorySelected;

  const HomeSearchOptions(
      {super.key,
      required this.intent,
      required this.onIntentChanged,
      required this.onCategorySelected});

  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            IntentSelector(intent: intent, onChanged: onIntentChanged),
            const SizedBox(height: 8),
            Text('Você pode consultar ajuda e doações sem criar uma conta.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontSize: 11, height: 1.4)),
            const SizedBox(height: 28),
            Text('Categorias',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            CategoryPicker(onSelected: onCategorySelected),
            const SizedBox(height: 16),
          ]);
}
