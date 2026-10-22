import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/auth/views/login_view.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/management/views/history_view.dart';
import 'package:apoio_app/ui/management/views/movement_view.dart';
import 'package:apoio_app/ui/management/views/points_view.dart';
import 'package:apoio_app/ui/management/views/stock_view.dart';
import 'package:flutter/material.dart';

class ManagementPage extends StatefulWidget {
  final ManagementRepository? api;
  const ManagementPage({super.key, this.api});
  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  ManagedPoint? _point;
  StockItem? _item;
  bool _history = false, _loggingOut = false, _mutating = false;
  int _stockGeneration = 0;
  @override
  void initState() {
    super.initState();
    widget.api?.addListener(_sessionChanged);
  }

  @override
  void dispose() {
    widget.api?.removeListener(_sessionChanged);
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() {
      if (widget.api?.session == null) {
        _point = null;
        _item = null;
        _history = false;
        _mutating = false;
      }
    });
  }

  void _back() {
    if (_loggingOut || _mutating) return;
    if (_item != null) {
      setState(() => _item = null);
    } else if (_point != null) {
      setState(() => _point = null);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await widget.api!.logout();
    } on ManagementFailure {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Você saiu neste dispositivo. Não foi possível confirmar o encerramento no servidor.')));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _reloadStock({bool success = false}) {
    setState(() {
      _item = null;
      _stockGeneration++;
      _mutating = false;
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Movimentação registrada. Estoque atualizado.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.api;
    final account = api?.session;
    final title = account == null
        ? 'Entrar na gestão'
        : _item != null
            ? (_history ? 'Histórico' : 'Movimentar estoque')
            : _point != null
                ? 'Estoque do ponto'
                : 'Meus pontos';
    Widget content;
    if (api == null) {
      content = const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'A gestão precisa da API local. Inicie o back-end e abra o aplicativo com iniciar.ps1 -Api. A consulta pública continua disponível.'));
    } else if (account == null) {
      content = LoginView(api: api);
    } else if (account.role != 'manager') {
      content = Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Olá, ${account.name}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text(
                'Esta conta pertence à prefeitura. O painel administrativo será implementado na próxima etapa.'),
          ]));
    } else if (_item != null) {
      content = _history
          ? HistoryView(api: api, item: _item!)
          : MovementView(
              api: api,
              item: _item!,
              onBusyChanged: (value) => setState(() => _mutating = value),
              onSuccess: () => _reloadStock(success: true),
              onReload: () => _reloadStock());
    } else if (_point != null) {
      content = StockView(
          key: ValueKey('${_point!.id}-$_stockGeneration'),
          api: api,
          point: _point!,
          onMove: (item) => setState(() {
                _item = item;
                _history = false;
              }),
          onHistory: (item) => setState(() {
                _item = item;
                _history = true;
              }));
    } else {
      content =
          PointsView(api: api, onSelect: (p) => setState(() => _point = p));
    }
    return PopScope(
        canPop: _point == null && !_loggingOut && !_mutating,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _back();
        },
        child: Scaffold(
            appBar: AppTopBar(
                sectionTitle: title,
                managementActive: true,
                navigationEnabled: !_loggingOut && !_mutating,
                onBack: _back,
                action: account == null
                    ? null
                    : TextButton(
                        onPressed: _loggingOut || _mutating ? null : _logout,
                        child: Text(_loggingOut ? 'Saindo…' : 'Sair'))),
            body: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: content))));
  }
}
