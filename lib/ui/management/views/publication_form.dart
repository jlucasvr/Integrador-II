import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:flutter/material.dart';

class PublicationForm extends StatefulWidget {
  final ManagementRepository api;
  final StockItem item;
  const PublicationForm({super.key, required this.api, required this.item});
  @override
  State<PublicationForm> createState() => _PublicationFormState();
}

class _PublicationFormState extends State<PublicationForm> {
  late final Map<String, bool> _options;
  bool _busy = false, _blocked = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final s = widget.item;
    _options = {
      'visible': s.visible,
      'public_quantity': s.publicQuantity,
      'distributable': s.distributable,
      'accepts_donation': s.acceptsDonation
    };
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.publish(widget.item, _options);
      if (mounted) Navigator.pop(context, true);
    } on ManagementFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _blocked = e.uncertain || e.status == 409 || e.status == 401;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Publicação do item'),
            automaticallyImplyLeading: !_busy),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Text(widget.item.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  for (final entry in {
                    'visible': [
                      'Exibir na consulta pública',
                      'Quando desativado, o item fica oculto para ajuda e doação.'
                    ],
                    'public_quantity': [
                      'Divulgar quantidade',
                      'Permite que a população consulte o saldo deste item.'
                    ],
                    'distributable': [
                      'Permitir distribuição',
                      'A disponibilidade também depende de saldo positivo.'
                    ],
                    'accepts_donation': [
                      'Aceitar doações',
                      'Inclui o item nas buscas de quem deseja doar.'
                    ]
                  }.entries)
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.value[0]),
                        subtitle: Text(entry.value[1]),
                        value: _options[entry.key]!,
                        onChanged: _busy || _blocked
                            ? null
                            : (v) => setState(() => _options[entry.key] = v)),
                  const SizedBox(height: 24),
                  Text(!_options['visible']!
                      ? 'O item ficará oculto na consulta pública.'
                      : 'Quantidade: ${_options['public_quantity']! ? '${widget.item.quantity} ${widget.item.unit}' : 'não divulgada'}. Distribuição: ${_options['distributable']! && widget.item.quantity > 0 ? 'disponível' : 'indisponível'}. Doações: ${_options['accepts_donation']! ? 'aceitas' : 'não aceitas'}. Instituição e ponto também precisam estar habilitados.'),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                            '$_error${_blocked ? ' Volte ao estoque e recarregue para conferir a publicação.' : ''}')),
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: _busy || _blocked ? null : _save,
                      child: Text(_busy ? 'Salvando…' : 'Salvar publicação')),
                ]))),
      ));
}
