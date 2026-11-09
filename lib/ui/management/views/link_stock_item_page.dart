import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/core/utils/normalize.dart';
import 'package:apoio_app/data/models/catalog_item.dart';
import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/widgets/inline_error.dart';
import 'package:apoio_app/ui/core/widgets/loading_indicator.dart';
import 'package:apoio_app/ui/management/widgets/load_failure.dart';
import 'package:flutter/material.dart';

class LinkStockItemPage extends StatefulWidget {
  final ManagementRepository api;
  final ManagedPoint point;

  const LinkStockItemPage({super.key, required this.api, required this.point});

  @override
  State<LinkStockItemPage> createState() => _LinkStockItemPageState();
}

class _LinkStockItemPageState extends State<LinkStockItemPage> {
  final _scroll = ScrollController();
  late Future<List<CatalogItem>> _catalog;
  String _search = '';
  String? _linkingId, _error;

  @override
  void initState() {
    super.initState();
    _catalog = widget.api.catalog(widget.point.id);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _link(CatalogItem item) async {
    if (_linkingId != null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _linkingId = item.id;
      _error = null;
    });
    try {
      await widget.api.linkStockItem(widget.point.id, item.id);
      if (mounted) Navigator.pop(context, true);
    } on ManagementFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        // Reconcile the catalog when another request may have created the link.
        if (error.status == 409 || error.uncertain || error.status >= 500) {
          _catalog = widget.api.catalog(widget.point.id);
        }
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } finally {
      if (mounted) setState(() => _linkingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _linkingId == null,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Vincular item'),
            automaticallyImplyLeading: _linkingId == null,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: CustomScrollView(controller: _scroll, slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.point.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                            'O item entra com saldo zero e fica oculto até você publicar.'),
                        const SizedBox(height: 16),
                        TextField(
                          enabled: _linkingId == null,
                          decoration: const InputDecoration(
                            labelText: 'Buscar no catálogo',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) => setState(() {
                            _search = normalize(value);
                          }),
                        ),
                        if (_error != null) InlineError(_error!),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<List<CatalogItem>>(
                  future: _catalog,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SliverToBoxAdapter(
                          child: LoadingIndicator());
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: LoadFailure(
                          error: snapshot.error,
                          onRetry: () => setState(() {
                            _error = null;
                            _catalog = widget.api.catalog(widget.point.id);
                          }),
                        ),
                      );
                    }
                    final catalog = snapshot.data!;
                    final items = catalog
                        .where((item) =>
                            normalize('${item.name} ${item.category}')
                                .contains(_search))
                        .toList();
                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(catalog.isEmpty
                              ? 'Nenhum item disponível para vincular a este ponto.'
                              : 'Nenhum item corresponde à busca no catálogo.'),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      sliver: SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle: Text('${item.category} · ${item.unit}'),
                            trailing: Tooltip(
                              message: 'Vincular ${item.name}',
                              child: OutlinedButton(
                                onPressed: _linkingId == null
                                    ? () => _link(item)
                                    : null,
                                child: Text(_linkingId == item.id
                                    ? 'Vinculando…'
                                    : 'Vincular'),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ),
      );
}
