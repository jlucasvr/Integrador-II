import 'package:apoio_app/data/models/support_point.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Uri mapsDirections(SupportPoint point) =>
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': point.coordinates == null
          ? [point.address, point.region].where((s) => s.isNotEmpty).join(', ')
          : '${point.coordinates!.latitude},${point.coordinates!.longitude}',
    });

Future<void> openPointLink(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Mantém o endereço acessível se o dispositivo bloquear o aplicativo.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Não foi possível abrir. Você pode copiar o link.'),
      action: SnackBarAction(
        label: 'Copiar link',
        onPressed: () => Clipboard.setData(ClipboardData(text: uri.toString())),
      ),
    ),
  );
}

void showPointContact(BuildContext context, SupportPoint point) {
  final contact = point.contact.trim();
  final phone =
      RegExp(r'^\+?[\d\s().-]+$').hasMatch(contact) &&
      contact.replaceAll(RegExp(r'\D'), '').length >= 10 &&
      contact.replaceAll(RegExp(r'\D'), '').length <= 13;
  final email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(contact);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fale com a organização',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(point.name),
            const SizedBox(height: 20),
            if (contact.isEmpty)
              const Text(
                'Esta organização ainda não informou um contato. Confira o endereço e o horário de atendimento.',
              )
            else ...[
              SelectableText(contact),
              const SizedBox(height: 20),
              if (phone || email) ...[
                FilledButton.icon(
                  onPressed: () => openPointLink(
                    context,
                    phone
                        ? Uri(
                            scheme: 'tel',
                            path: contact.replaceAll(RegExp(r'[^\d+]'), ''),
                          )
                        : Uri(scheme: 'mailto', path: contact),
                  ),
                  icon: Icon(phone ? Icons.call_outlined : Icons.mail_outline),
                  label: Text(
                    phone ? 'Ligar para a organização' : 'Enviar e-mail',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: contact));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contato copiado.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copiar contato'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar para a organização'),
            ),
          ],
        ),
      ),
    ),
  );
}
