import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/models/municipal_institution.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/widgets/inline_error.dart';
import 'package:flutter/material.dart';

class InstitutionForm extends StatefulWidget {
  const InstitutionForm({super.key, required this.api, this.institution});

  final ManagementRepository api;
  final MunicipalInstitution? institution;

  @override
  State<InstitutionForm> createState() => _InstitutionFormState();
}

class _InstitutionFormState extends State<InstitutionForm> {
  final _form = GlobalKey<FormState>();
  final _text = TextEditingController();
  InstitutionStatus? _status;
  String? _error;
  bool _saving = false, _mustCheck = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _mustCheck || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final institution = widget.institution;
    try {
      if (institution == null) {
        await widget.api.createInstitution(_text.text);
      } else {
        await widget.api.verifyInstitution(
          institution.id,
          _status!,
          _text.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ManagementFailure catch (error) {
      if (!mounted) return;
      if (error.status == 401) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _mustCheck =
            error.uncertain || error.status >= 500 || error.status == 404;
        _error = _mustCheck
            ? '${error.message} Feche o formulário e confira a situação antes de tentar novamente.'
            : error.message;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final institution = widget.institution;
    final canEdit = !_saving && !_mustCheck;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        scrollable: true,
        title: Text(
          institution == null ? 'Cadastrar instituição' : 'Alterar situação',
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (institution == null)
                  const Text(
                    'A instituição será cadastrada como pendente de verificação.',
                  )
                else ...[
                  Text(
                    institution.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('Situação atual: ${institution.status.label}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<InstitutionStatus>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Nova situação',
                    ),
                    items: [
                      for (final status in InstitutionStatus.values)
                        if (status != institution.status)
                          DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                    ],
                    onChanged: canEdit
                        ? (value) => setState(() => _status = value)
                        : null,
                    validator: (value) =>
                        value == null ? 'Selecione a nova situação.' : null,
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 8),
                    Text(switch (_status!) {
                      InstitutionStatus.verified =>
                        'Os pontos ativos poderão voltar à consulta pública, conforme a publicação de cada item.',
                      InstitutionStatus.pending =>
                        'Os pontos ficam fora da consulta pública enquanto a instituição estiver pendente.',
                      InstitutionStatus.suspended =>
                        'Os pontos ficam fora da consulta pública enquanto a instituição estiver suspensa.',
                    }),
                  ],
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _text,
                  enabled: canEdit,
                  maxLength: institution == null ? 150 : 500,
                  minLines: institution == null ? 1 : 2,
                  maxLines: institution == null ? 1 : 4,
                  decoration: InputDecoration(
                    labelText: institution == null
                        ? 'Nome da instituição'
                        : 'Justificativa',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? (institution == null
                            ? 'Informe o nome.'
                            : 'Informe a justificativa.')
                      : null,
                ),
                if (_error != null) InlineError(_error!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(_mustCheck ? 'Voltar à lista' : 'Cancelar'),
          ),
          FilledButton(
            onPressed: canEdit ? _save : null,
            child: Text(
              _saving
                  ? 'Salvando…'
                  : institution == null
                  ? 'Cadastrar'
                  : 'Confirmar decisão',
            ),
          ),
        ],
      ),
    );
  }
}
