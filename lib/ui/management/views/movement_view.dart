import 'package:apoio_app/data/models/movement_type.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/widgets/inline_error.dart';
import 'package:apoio_app/ui/management/view_models/movement_view_model.dart';
import 'package:flutter/material.dart';

class MovementView extends StatefulWidget {
  final ManagementRepository api;
  final StockItem item;
  final VoidCallback onSuccess, onReload;
  final ValueChanged<bool> onBusyChanged;
  const MovementView(
      {super.key,
      required this.api,
      required this.item,
      required this.onSuccess,
      required this.onReload,
      required this.onBusyChanged});
  @override
  State<MovementView> createState() => _MovementViewState();
}

class _MovementViewState extends State<MovementView> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController(), _note = TextEditingController();
  late final MovementViewModel _viewModel;
  int? get _balance => _viewModel.balance(_quantity.text);
  @override
  void initState() {
    super.initState();
    _viewModel = MovementViewModel(widget.api, widget.item)
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _viewModel.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_viewModel.busy ||
        _viewModel.needsReload ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    widget.onBusyChanged(true);
    final success = await _viewModel.submit(_quantity.text, _note.text);
    if (!mounted) return;
    widget.onBusyChanged(false);
    if (success) widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_viewModel.busy,
      child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.item.name,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(
                            'Saldo atual: ${widget.item.quantity} ${widget.item.unit}'),
                        const SizedBox(height: 24),
                        SegmentedButton<MovementType>(
                            showSelectedIcon: false,
                            segments: MovementType.values
                                .map((t) => ButtonSegment(
                                    value: t, label: Text(t.label)))
                                .toList(),
                            selected: {_viewModel.type},
                            onSelectionChanged:
                                _viewModel.busy || _viewModel.needsReload
                                    ? null
                                    : (v) => _viewModel.setType(v.first)),
                        const SizedBox(height: 24),
                        TextFormField(
                            key: const ValueKey('movement-quantity'),
                            controller: _quantity,
                            enabled:
                                !_viewModel.busy && !_viewModel.needsReload,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                                labelText:
                                    _viewModel.type == MovementType.adjustment
                                        ? 'Quantidade real encontrada'
                                        : 'Quantidade (${widget.item.unit})'),
                            validator: _viewModel.validateQuantity),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _note,
                            enabled:
                                !_viewModel.busy && !_viewModel.needsReload,
                            maxLength: 500,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                labelText: 'Observação (opcional)')),
                        const SizedBox(height: 16),
                        Semantics(
                            liveRegion: true,
                            child: Text(
                                _balance == null
                                    ? 'Informe a quantidade para conferir o saldo resultante.'
                                    : 'Saldo após ${_viewModel.type.label.toLowerCase()}: $_balance ${widget.item.unit}',
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        if (_viewModel.type == MovementType.adjustment)
                          const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                  'O ajuste substitui o saldo pela quantidade real encontrada.')),
                        if (_viewModel.error != null)
                          InlineError(_viewModel.error!),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _viewModel.busy || _viewModel.needsReload
                                ? null
                                : _submit,
                            child: Text(_viewModel.busy
                                ? 'Registrando…'
                                : 'Confirmar ${_viewModel.type.label.toLowerCase()}')),
                        if (_viewModel.needsReload)
                          OutlinedButton(
                              onPressed:
                                  _viewModel.busy ? null : widget.onReload,
                              child:
                                  const Text('Conferir estoque e histórico')),
                      ])))));
}
