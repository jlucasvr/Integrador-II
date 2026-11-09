import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:apoio_app/data/services/location_service.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/search/views/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ApoioApp extends StatelessWidget {
  final PointRepository repository;
  final ManagementRepository? managementApi;
  final LocationService locationService;
  const ApoioApp(
      {super.key,
      required this.repository,
      this.managementApi,
      this.locationService = const GeolocatorLocationService()});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Encontrar apoio',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: wireframeTheme(),
      builder: const bool.fromEnvironment('LOCAL_EVALUATION')
          ? (context, child) => Column(children: [
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const SafeArea(
                    bottom: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text('Avaliação local · dados fictícios',
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
                Expanded(child: child!),
              ])
          : null,
      home: SearchPage(
          repository: repository,
          managementApi: managementApi,
          locationService: locationService));
}
