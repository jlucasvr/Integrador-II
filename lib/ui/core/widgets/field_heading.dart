import 'package:flutter/material.dart';

class FieldHeading extends StatelessWidget {
  final String text;
  const FieldHeading(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)));
}
