import 'dart:math';

import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:flutter/material.dart';

class PointForm extends StatefulWidget {
  final ManagementRepository api;
  final ManagedPoint? point;
  const PointForm({super.key, required this.api, this.point});
  @override
  State<PointForm> createState() => _PointFormState();
}

class _PointFormState extends State<PointForm> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  late final Future<List<Map<String, dynamic>>> _institutions;
  String? _institution, _error, _creationKey;
  bool _busy = false, _blocked = false, _active = true;
  bool _retryCreate = false;
  bool get _editable => !_busy && !_blocked && !_retryCreate;

  String get _recoveryHint {
    if (_blocked) {
      return ' Volte à lista e atualize os pontos para conferir os dados.';
    }
    if (_retryCreate) {
      return ' Tente confirmar o mesmo cadastro. Se sair do formulário, confira a lista antes de cadastrar novamente.';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    final p = widget.point;
    _fields = [
      p?.name ?? '',
      p?.address ?? '',
      p?.region ?? '',
      p?.hours ?? '',
      p?.contact ?? '',
      p?.latitude.toString() ?? '',
      p?.longitude.toString() ?? ''
    ].map((text) => TextEditingController(text: text)).toList();
    _institution = p?.institutionId;
    _active = p?.active ?? true;
    _institutions = widget.api.institutions();
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _blocked || !_form.currentState!.validate()) return;
    if (widget.point == null && _creationKey == null) {
      final random = Random.secure();
      _creationKey = List.generate(
              16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.savePoint({
        'institution_id': _institution,
        for (var i = 0; i < 5; i++)
          ['name', 'address', 'region', 'hours', 'contact'][i]:
              _fields[i].text.trim(),
        'latitude': double.parse(_fields[5].text.replaceAll(',', '.')),
        'longitude': double.parse(_fields[6].text.replaceAll(',', '.')),
        'active': _active,
      }, point: widget.point, idempotencyKey: _creationKey);
      if (mounted) Navigator.pop(context, true);
    } on ManagementFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _retryCreate = _retryCreate || (widget.point == null && e.uncertain);
          _blocked = (e.uncertain && !_retryCreate) ||
              e.status == 409 ||
              e.status == 401 ||
              e.status == 403;
          if (!_retryCreate) _creationKey = null;
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
              title: Text(
                  widget.point == null ? 'Cadastrar ponto' : 'Editar ponto'),
              automaticallyImplyLeading: !_busy),
          body: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _institutions,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                                'Não foi possível carregar as instituições. Volte e tente novamente.'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Form(
                          key: _form,
                          child: ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                DropdownButtonFormField<String>(
                                    initialValue: _institution,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Instituição'),
                                    items: snapshot.data!
                                        .map((i) => DropdownMenuItem(
                                            value: i['id'] as String,
                                            child: Text(i['name'] as String)))
                                        .toList(),
                                    onChanged:
                                        !_editable || widget.point != null
                                            ? null
                                            : (v) => _institution = v,
                                    validator: (v) => v == null
                                        ? 'Selecione uma instituição.'
                                        : null),
                                const SizedBox(height: 16),
                                for (var i = 0; i < _fields.length; i++)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: TextFormField(
                                        controller: _fields[i],
                                        enabled: _editable,
                                        maxLength: [
                                          150,
                                          300,
                                          150,
                                          250,
                                          250,
                                          24,
                                          24
                                        ][i],
                                        decoration: InputDecoration(
                                            labelText: [
                                          'Nome do ponto',
                                          'Endereço',
                                          'Cidade / região',
                                          'Horário de atendimento',
                                          'Contato (opcional)',
                                          'Latitude',
                                          'Longitude'
                                        ][i]),
                                        keyboardType: i >= 5
                                            ? const TextInputType
                                                .numberWithOptions(
                                                decimal: true, signed: true)
                                            : TextInputType.text,
                                        validator: (v) {
                                          if (i == 4) return null;
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Preencha este campo.';
                                          }
                                          if (i >= 5) {
                                            final n = double.tryParse(
                                                v.replaceAll(',', '.'));
                                            if (n == null ||
                                                !n.isFinite ||
                                                n.abs() > (i == 5 ? 90 : 180)) {
                                              return 'Informe uma coordenada válida.';
                                            }
                                          }
                                          return null;
                                        },
                                      )),
                                SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Ponto ativo'),
                                    subtitle: const Text(
                                        'Pontos inativos ficam fora da consulta pública.'),
                                    value: _active,
                                    onChanged: !_editable
                                        ? null
                                        : (v) => setState(() => _active = v)),
                                if (_error != null)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Text('$_error$_recoveryHint')),
                                FilledButton(
                                    onPressed: _busy || _blocked ? null : _save,
                                    child: Text(_busy
                                        ? 'Salvando…'
                                        : _retryCreate
                                            ? 'Confirmar cadastro'
                                            : 'Salvar ponto')),
                              ]));
                    },
                  ))),
        ),
      );
}
