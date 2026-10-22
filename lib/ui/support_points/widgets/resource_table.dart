import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/ui/support_points/formatters/resource_status.dart';
import 'package:flutter/material.dart';

class ResourceTable extends StatelessWidget {
  final List<Resource> resources;
  const ResourceTable({super.key, required this.resources});
  @override
  Widget build(BuildContext context) => Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      border: TableBorder(
          horizontalInside:
              BorderSide(color: Theme.of(context).colorScheme.outline)),
      children: [
        const TableRow(children: [
          Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Item',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Situação',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)))
        ]),
        ...resources.map((r) => TableRow(children: [
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('${r.name}\n${r.unit}')),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(resourceStatus(r))),
            ])),
      ]);
}
