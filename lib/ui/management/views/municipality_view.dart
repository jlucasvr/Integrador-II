import 'package:apoio_app/core/utils/normalize.dart';
import 'package:apoio_app/data/models/municipal_institution.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/view_models/async_list_view_model.dart';
import 'package:apoio_app/ui/core/widgets/loading_indicator.dart';
import 'package:apoio_app/ui/management/views/institution_form.dart';
import 'package:apoio_app/ui/management/widgets/load_failure.dart';
import 'package:apoio_app/ui/management/widgets/operation_layout.dart';
import 'package:flutter/material.dart';

class MunicipalityView extends StatefulWidget {
  const MunicipalityView({
    super.key,
    required this.api,
    required this.selectedId,
    required this.onSelect,
  });

  final ManagementRepository api;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  State<MunicipalityView> createState() => _MunicipalityViewState();
}

class _MunicipalityViewState extends State<MunicipalityView> {
  static const _columns = [54, 22, 24];
  late final AsyncListViewModel<MunicipalInstitution> _list;
  final _search = TextEditingController();
  InstitutionStatus? _filter;
  bool _pendingFirst = true;

  @override
  void initState() {
    super.initState();
    _list = AsyncListViewModel(widget.api.municipalInstitutions)
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _list.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm([MunicipalInstitution? institution]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          InstitutionForm(api: widget.api, institution: institution),
    );
    if (!mounted) return;
    _list.reload();
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            institution == null
                ? 'Instituição cadastrada como pendente.'
                : 'Situação da instituição atualizada.',
          ),
        ),
      );
    }
  }

  OperationStatus _status(InstitutionStatus status) =>
      OperationStatus(status.label, switch (status) {
        InstitutionStatus.pending => Icons.schedule,
        InstitutionStatus.verified => Icons.verified_outlined,
        InstitutionStatus.suspended => Icons.pause_circle_outline,
      });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => FutureBuilder<List<MunicipalInstitution>>(
      future: _list.request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return LoadFailure(error: snapshot.error, onRetry: _list.reload);
        }
        final institutions = snapshot.data!;
        final id = widget.selectedId;
        if (id != null) {
          final institution = institutions.where((i) => i.id == id).firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => widget.onSelect(null),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Todas as instituições'),
                ),
              ),
              if (institution == null)
                const OperationEmpty(
                  'Instituição indisponível',
                  'Volte à lista para consultar as instituições do seu município.',
                )
              else ...[
                const SizedBox(height: 16),
                OperationHeading(
                  title: institution.name,
                  description: 'Instituição do seu município',
                ),
                const SizedBox(height: 24),
                Text(
                  'Situação da verificação',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _status(institution.status),
                const SizedBox(height: 8),
                Text(
                  institution.status == InstitutionStatus.verified
                      ? 'Os pontos ativos podem aparecer na consulta pública.'
                      : 'Os pontos da instituição estão fora da consulta pública.',
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _openForm(institution),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Alterar situação'),
                  ),
                ),
              ],
            ],
          );
        }
        final query = normalize(_search.text);
        final counts = {
          for (final status in InstitutionStatus.values) status: 0,
        };
        for (final institution in institutions) {
          counts.update(institution.status, (count) => count + 1);
        }
        final results =
            institutions
                .where(
                  (i) =>
                      (_filter == null || i.status == _filter) &&
                      normalize(i.name).contains(query),
                )
                .toList()
              ..sort((a, b) {
                if (_pendingFirst) {
                  final priority =
                      (a.status == InstitutionStatus.pending ? 0 : 1).compareTo(
                        b.status == InstitutionStatus.pending ? 0 : 1,
                      );
                  if (priority != 0) return priority;
                }
                return normalize(a.name).compareTo(normalize(b.name));
              });
        final wide =
            constraints.maxWidth >= 760 &&
            MediaQuery.textScalerOf(context).scale(14) <= 17;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OperationHeading(
                      title: 'Instituições do município',
                      description:
                          'Cadastre instituições e acompanhe a situação da verificação.',
                      actions: [
                        FilledButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Cadastrar instituição'),
                        ),
                        TextButton.icon(
                          onPressed: _list.reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Atualizar lista'),
                        ),
                      ],
                    ),
                    if (institutions.isEmpty)
                      const OperationEmpty(
                        'Nenhuma instituição cadastrada',
                        'Cadastre a primeira instituição para iniciar a análise.',
                      )
                    else ...[
                      const SizedBox(height: 24),
                      TextField(
                        controller: _search,
                        onChanged: (_) => _refresh(),
                        decoration: const InputDecoration(
                          labelText: 'Buscar instituição',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _filterChip('Todas · ${institutions.length}', null),
                          _filterChip(
                            'Pendentes · ${counts[InstitutionStatus.pending]}',
                            InstitutionStatus.pending,
                          ),
                          _filterChip(
                            'Verificadas · ${counts[InstitutionStatus.verified]}',
                            InstitutionStatus.verified,
                          ),
                          _filterChip(
                            'Suspensas · ${counts[InstitutionStatus.suspended]}',
                            InstitutionStatus.suspended,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _pendingFirst = !_pendingFirst),
                          icon: const Icon(Icons.sort, size: 18),
                          label: Text(
                            _pendingFirst
                                ? 'Ordem: pendentes primeiro'
                                : 'Ordem: nome de A a Z',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          '${results.length} de ${institutions.length} instituições',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (results.isEmpty)
                        const OperationEmpty(
                          'Nenhuma instituição encontrada',
                          'Tente outro nome ou selecione Todas para remover o filtro.',
                        ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 72),
              sliver: SliverList.builder(
                itemCount:
                    results.length + (wide && results.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (wide && index == 0) {
                    return const OperationColumns(
                      heading: true,
                      widths: _columns,
                      cells: [
                        Text('Instituição'),
                        Text('Situação'),
                        Text('Ações'),
                      ],
                    );
                  }
                  final institution = results[wide ? index - 1 : index];
                  final name = Text(
                    institution.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  );
                  final status = _status(institution.status);
                  final action = OutlinedButton(
                    onPressed: () => widget.onSelect(institution.id),
                    child: const Text('Ver detalhes'),
                  );
                  if (wide) {
                    return OperationColumns(
                      widths: _columns,
                      cells: [
                        name,
                        status,
                        Align(alignment: Alignment.centerLeft, child: action),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      name,
                      status,
                      const SizedBox(height: 8),
                      action,
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _filterChip(String label, InstitutionStatus? status) =>
      OperationFilterChip(
        label: label,
        selected: _filter == status,
        onSelect: () => setState(() => _filter = status),
      );
}
