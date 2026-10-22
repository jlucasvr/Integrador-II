import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/management/views/management_page.dart';
import 'package:flutter/material.dart';

void openManagement(BuildContext context, ManagementRepository? repository) {
  Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ManagementPage(api: repository)));
}
