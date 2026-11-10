import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/auth/views/login_view.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/management/views/history_view.dart';
import 'package:apoio_app/ui/management/views/movement_view.dart';
import 'package:apoio_app/ui/management/views/municipality_view.dart';
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
  String? _institutionId;
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
        _institutionId = null;
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
    } else if (_institutionId != null) {
      setState(() => _institutionId = null);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Você saiu neste dispositivo. Não foi possível confirmar o encerramento no servidor.',
            ),
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimentação registrada. Estoque atualizado.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.api;
    final account = api?.session;
    final isMunicipality = account?.role == 'municipality';
    final title = account == null
        ? 'Entrar na gestão'
        : isMunicipality
        ? 'Prefeitura'
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
          'A gestão precisa da API local. Inicie o back-end e abra o aplicativo com iniciar.ps1 -Api. A consulta pública continua disponível.',
        ),
      );
    } else if (account == null) {
      content = LoginView(api: api);
    } else if (isMunicipality) {
      content = MunicipalityView(
        api: api,
        selectedId: _institutionId,
        onSelect: (id) => setState(() => _institutionId = id),
      );
    } else if (account.role == 'manager') {
      final point = _point;
      final item = _item;
      content = IndexedStack(
        index: item != null ? 2 : (point != null ? 1 : 0),
        children: [
          PointsView(api: api, onSelect: (p) => setState(() => _point = p)),
          if (point != null)
            StockView(
              key: ValueKey(point.id),
              revision: _stockGeneration,
              api: api,
              point: point,
              onMove: (item) => setState(() {
                _item = item;
                _history = false;
              }),
              onHistory: (item) => setState(() {
                _item = item;
                _history = true;
              }),
            ),
          if (point != null && item != null)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: _mutating ? null : _back,
                        child: const Text('Voltar ao estoque'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: _history
                          ? HistoryView(api: api, item: item)
                          : MovementView(
                              api: api,
                              item: item,
                              onBusyChanged: (value) =>
                                  setState(() => _mutating = value),
                              onSuccess: () => _reloadStock(success: true),
                              onReload: () => _reloadStock(),
                            ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    } else {
      content = const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Sua conta não tem acesso à gestão.'),
      );
    }
    return PopScope(
      canPop:
          _point == null &&
          _institutionId == null &&
          !_loggingOut &&
          !_mutating,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppTopBar(
          sectionTitle: title,
          maxWidth: account == null ? 620 : 1200,
          managementActive: true,
          navigationEnabled: !_loggingOut && !_mutating,
          onBack: _back,
          action: account == null
              ? null
              : TextButton(
                  onPressed: _loggingOut || _mutating ? null : _logout,
                  child: Text(_loggingOut ? 'Saindo…' : 'Sair'),
                ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: account == null ? 900 : 1200),
            child: content,
          ),
        ),
      ),
    );
  }
}
