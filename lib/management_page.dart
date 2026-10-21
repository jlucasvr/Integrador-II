import 'package:flutter/material.dart';
import 'management_api.dart';
import 'data.dart' show normalize;

String dateLabel(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}, ${two(d.hour)}:${two(d.minute)}';
}

class ManagementPage extends StatefulWidget {
  final ManagementApi? api;
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
            appBar: AppBar(
                title: Text(title),
                leading: IconButton(
                    onPressed: _loggingOut || _mutating ? null : _back,
                    tooltip: 'Voltar',
                    icon: const Icon(Icons.arrow_back)),
                actions: account == null
                    ? null
                    : [
                        TextButton(
                            onPressed:
                                _loggingOut || _mutating ? null : _logout,
                            child: Text(_loggingOut ? 'Saindo…' : 'Sair'))
                      ]),
            body: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: content))));
  }
}

class LoginView extends StatefulWidget {
  final ManagementApi api;
  const LoginView({super.key, required this.api});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _busy = false, _showPassword = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.login(_email.text, _password.text);
    } on ManagementFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Não foi possível concluir o acesso. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Acesso da instituição',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text(
                        'Use a conta vinculada à sua instituição para administrar o estoque.'),
                    if (widget.api.signInNotice != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(widget.api.signInNotice!,
                              semanticsLabel: widget.api.signInNotice)),
                    const SizedBox(height: 24),
                    TextFormField(
                        key: const ValueKey('login-email'),
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (v) => v == null ||
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v.trim())
                            ? 'Informe um e-mail válido.'
                            : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        key: const ValueKey('login-password'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: !_showPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                            labelText: 'Senha',
                            suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                                tooltip: _showPassword
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility))),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Informe sua senha.'
                            : null),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Semantics(
                              liveRegion: true,
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error)))),
                    const SizedBox(height: 24),
                    FilledButton(
                        onPressed: _busy ? null : _login,
                        child: Text(_busy ? 'Entrando…' : 'Entrar')),
                    const SizedBox(height: 16),
                    const Text(
                        'A consulta pública não exige login. O acesso à gestão depende de um vínculo autorizado.'),
                  ]))));
}

class LoadFailure extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const LoadFailure({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error is ManagementFailure
            ? (error as ManagementFailure).message
            : 'Não foi possível carregar as informações.'),
        const SizedBox(height: 16),
        OutlinedButton(
            onPressed: onRetry, child: const Text('Tentar novamente')),
      ]));
}

const loading = Center(child: CircularProgressIndicator());

class PointsView extends StatefulWidget {
  final ManagementApi api;
  final ValueChanged<ManagedPoint> onSelect;
  const PointsView({super.key, required this.api, required this.onSelect});
  @override
  State<PointsView> createState() => _PointsViewState();
}

class _PointsViewState extends State<PointsView> {
  late Future<List<ManagedPoint>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.api.points();
  }

  void _reload() => setState(() => _future = widget.api.points());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<ManagedPoint>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return loading;
        if (snapshot.hasError) {
          return LoadFailure(error: snapshot.error, onRetry: _reload);
        }
        final points = snapshot.data!;
        return ListView(padding: const EdgeInsets.all(24), children: [
          Text('Olá, ${widget.api.session?.name ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Escolha o ponto cujo estoque você quer administrar.'),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar pontos'))),
          if (points.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                    'Você ainda não tem pontos vinculados. Solicite à prefeitura o acesso à sua instituição.')),
          ...points.map((p) => Column(children: [
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.name),
                    subtitle: Text('${p.institution}\n${p.address}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onSelect(p)),
                const Divider()
              ])),
        ]);
      });
}

class StockView extends StatefulWidget {
  final ManagementApi api;
  final ManagedPoint point;
  final ValueChanged<StockItem> onMove, onHistory;
  const StockView(
      {super.key,
      required this.api,
      required this.point,
      required this.onMove,
      required this.onHistory});
  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView> {
  late Future<List<StockItem>> _future;
  String _search = '';
  @override
  void initState() {
    super.initState();
    _future = widget.api.stock(widget.point.id);
  }

  void _reload() => setState(() => _future = widget.api.stock(widget.point.id));
  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.point.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(widget.point.hours),
                  const SizedBox(height: 16),
                  TextField(
                      decoration: const InputDecoration(
                          labelText: 'Buscar no estoque',
                          prefixIcon: Icon(Icons.search)),
                      onChanged: (v) => setState(() => _search = normalize(v))),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recarregar estoque'))),
                ])),
        Expanded(
            child: FutureBuilder<List<StockItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return loading;
                  }
                  if (snapshot.hasError) {
                    return LoadFailure(error: snapshot.error, onRetry: _reload);
                  }
                  final stocks = snapshot.data!
                      .where((s) => normalize('${s.name} ${s.category}')
                          .contains(_search))
                      .toList();
                  if (stocks.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Nenhum item encontrado no estoque deste ponto.'));
                  }
                  return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: stocks.length,
                      itemBuilder: (context, index) {
                        final s = stocks[index];
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(s.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Text('Saldo: ${s.quantity} ${s.unit}'),
                                  Text('Atualizado: ${dateLabel(s.updatedAt)}'),
                                  Text(!s.visible
                                      ? 'Item oculto da consulta pública'
                                      : s.publicQuantity
                                          ? 'Quantidade publicada'
                                          : 'Quantidade não divulgada'),
                                  Text(s.distributable && s.quantity > 0
                                      ? 'Disponível para distribuição'
                                      : 'Indisponível para distribuição'),
                                  Text(s.acceptsDonation
                                      ? 'Aceita doação'
                                      : 'Não aceita doação'),
                                  const SizedBox(height: 12),
                                  Wrap(spacing: 12, runSpacing: 8, children: [
                                    FilledButton(
                                        onPressed: () => widget.onMove(s),
                                        child: const Text('Movimentar')),
                                    OutlinedButton(
                                        onPressed: () => widget.onHistory(s),
                                        child: const Text('Histórico')),
                                  ]),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                ]));
                      });
                })),
      ]);
}

class MovementView extends StatefulWidget {
  final ManagementApi api;
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
  MovementType _type = MovementType.entry;
  bool _busy = false, _needsReload = false;
  String? _error;
  int? get _balance {
    final q = int.tryParse(_quantity.text);
    if (q == null || q < 0 || q > 1000000000) return null;
    return switch (_type) {
      MovementType.entry => widget.item.quantity + q,
      MovementType.exit => widget.item.quantity - q,
      MovementType.adjustment => q
    };
  }

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _needsReload || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyChanged(true);
    try {
      await widget.api
          .move(widget.item, _type, int.parse(_quantity.text), _note.text);
      if (mounted) widget.onSuccess();
    } on ManagementFailure catch (e) {
      if (mounted) {
        setState(() {
          _needsReload = e.status == 409 || e.uncertain;
          _error = e.uncertain
              ? 'Não recebemos confirmação. Confira o saldo e o histórico antes de repetir a movimentação.'
              : e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _needsReload = true;
          _error = 'Confira o saldo e o histórico antes de tentar novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
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
                            selected: {_type},
                            onSelectionChanged: _busy || _needsReload
                                ? null
                                : (v) => setState(() => _type = v.first)),
                        const SizedBox(height: 24),
                        TextFormField(
                            key: const ValueKey('movement-quantity'),
                            controller: _quantity,
                            enabled: !_busy && !_needsReload,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                                labelText: _type == MovementType.adjustment
                                    ? 'Quantidade real encontrada'
                                    : 'Quantidade (${widget.item.unit})'),
                            validator: (v) {
                              final q = int.tryParse(v ?? '');
                              if (q == null || q < 0 || q > 1000000000) {
                                return 'Informe uma quantidade inteira válida.';
                              }
                              if (_type != MovementType.adjustment && q == 0) {
                                return 'Informe uma quantidade maior que zero.';
                              }
                              if (_type == MovementType.exit &&
                                  q > widget.item.quantity) {
                                return 'A saída excede o saldo de ${widget.item.quantity}.';
                              }
                              if (_type == MovementType.entry &&
                                  widget.item.quantity + q > 1000000000) {
                                return 'O saldo máximo foi excedido.';
                              }
                              return null;
                            }),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _note,
                            enabled: !_busy && !_needsReload,
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
                                    : 'Saldo após ${_type.label.toLowerCase()}: $_balance ${widget.item.unit}',
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        if (_type == MovementType.adjustment)
                          const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                  'O ajuste substitui o saldo pela quantidade real encontrada.')),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Semantics(
                                  liveRegion: true,
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error)))),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _busy || _needsReload ? null : _submit,
                            child: Text(_busy
                                ? 'Registrando…'
                                : 'Confirmar ${_type.label.toLowerCase()}')),
                        if (_needsReload)
                          OutlinedButton(
                              onPressed: _busy ? null : widget.onReload,
                              child:
                                  const Text('Conferir estoque e histórico')),
                      ])))));
}

class HistoryView extends StatefulWidget {
  final ManagementApi api;
  final StockItem item;
  const HistoryView({super.key, required this.api, required this.item});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late Future<List<StockMovement>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.api.history(widget.item.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<StockMovement>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return loading;
        if (snapshot.hasError) {
          return LoadFailure(
              error: snapshot.error,
              onRetry: () =>
                  setState(() => _future = widget.api.history(widget.item.id)));
        }
        return ListView(padding: const EdgeInsets.all(24), children: [
          Text(widget.item.name, style: Theme.of(context).textTheme.titleLarge),
          const Text('Até 100 movimentações mais recentes.'),
          const SizedBox(height: 24),
          if (snapshot.data!.isEmpty)
            const Text('Nenhuma movimentação registrada para este item.'),
          ...snapshot.data!.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        '${MovementType.values.firstWhere((t) => t.name == m.type).label}: ${m.quantity} ${widget.item.unit}',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('Saldo: ${m.previousBalance} → ${m.resultingBalance}'),
                    Text(dateLabel(m.createdAt)),
                    Text('Responsável: ${m.responsible}'),
                    if (m.note.isNotEmpty) Text(m.note),
                    const Divider(),
                  ]))),
        ]);
      });
}
