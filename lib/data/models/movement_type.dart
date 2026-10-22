enum MovementType { entry, exit, adjustment }

extension MovementLabel on MovementType {
  String get label => switch (this) {
        MovementType.entry => 'Entrada',
        MovementType.exit => 'Saída',
        MovementType.adjustment => 'Ajuste',
      };
}
