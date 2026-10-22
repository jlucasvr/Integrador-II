import 'package:apoio_app/app/app.dart';
import 'package:apoio_app/app/app_dependencies.dart';
import 'package:flutter/material.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = AppDependencies.fromEnvironment();
  }

  @override
  void dispose() {
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ApoioApp(
      repository: _dependencies.points,
      managementApi: _dependencies.management);
}
