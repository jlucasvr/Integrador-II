import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_availability_indicator.dart';
import 'package:apoio_app/ui/support_points/widgets/detail_card.dart';
import 'package:flutter/material.dart';

IconData resourceIcon(String category) => switch (category) {
  'Água' => Icons.water_drop_outlined,
  'Alimentos' => Icons.restaurant_rounded,
  'Higiene' => Icons.sanitizer_outlined,
  'Abrigo' || 'Cobertores' => Icons.bed_outlined,
  'Roupas' || 'Agasalhos' => Icons.checkroom_rounded,
  'Calçados' => Icons.hiking_outlined,
  'Medicamentos' => Icons.medication_outlined,
  'Infantil' => Icons.child_care_rounded,
  _ => Icons.inventory_2_outlined,
};

class ResourceCard extends StatelessWidget {
  const ResourceCard({super.key, required this.resource});
  final Resource resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DetailCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 44,
              child: Icon(
                resourceIcon(resource.category),
                size: 22,
                color: theme.colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ResourceAvailabilityIndicator(resource: resource),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      resource.acceptsDonation
                          ? Icons.volunteer_activism_outlined
                          : Icons.block_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        resource.acceptsDonation
                            ? 'Aceita doação deste item'
                            : 'Não recebe doação deste item',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
