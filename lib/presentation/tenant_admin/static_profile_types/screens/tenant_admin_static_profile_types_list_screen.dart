import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/controllers/tenant_admin_static_profile_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminStaticProfileTypesListScreen extends StatefulWidget {
  const TenantAdminStaticProfileTypesListScreen({super.key});

  @override
  State<TenantAdminStaticProfileTypesListScreen> createState() =>
      _TenantAdminStaticProfileTypesListScreenState();
}

class _TenantAdminStaticProfileTypesListScreenState
    extends State<TenantAdminStaticProfileTypesListScreen> {
  final TenantAdminStaticProfileTypesController _controller =
      GetIt.I.get<TenantAdminStaticProfileTypesController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _controller.loadTypes();
    _controller.loadTaxonomies();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      _controller.loadNextTypesPage();
    }
  }

  Future<void> _confirmDelete(String type, String label) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover tipo de ativo',
      message: 'Remover "$label" ($type)?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }

    _controller.submitDeleteType(type);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.successMessageStreamValue,
      builder: (context, successMessage) {
        _handleSuccessMessage(successMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.actionErrorMessageStreamValue,
          builder: (context, actionErrorMessage) {
            _handleActionErrorMessage(actionErrorMessage);
            return StreamValueBuilder<String?>(
              streamValue: _controller.errorStreamValue,
              builder: (context, error) {
                return StreamValueBuilder<bool>(
                  streamValue: _controller.hasMoreTypesStreamValue,
                  builder: (context, hasMore) {
                    return StreamValueBuilder<bool>(
                      streamValue: _controller.isTypesPageLoadingStreamValue,
                      builder: (context, isPageLoading) {
                        return StreamValueBuilder<
                            List<TenantAdminStaticProfileTypeDefinition>?>(
                          streamValue: _controller.typesStreamValue,
                          onNullWidget: _buildScaffold(
                            context: context,
                            error: error,
                            body: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          builder: (context, types) {
                            final loadedTypes = types ??
                                const <TenantAdminStaticProfileTypeDefinition>[];
                            return _buildScaffold(
                              context: context,
                              error: error,
                              body: loadedTypes.isEmpty
                                  ? const TenantAdminEmptyState(
                                      icon: Icons.layers_outlined,
                                      title: 'Nenhum tipo de ativo',
                                      description:
                                          'Use "Criar tipo" para definir o primeiro tipo de ativo estático.',
                                    )
                                  : _buildTypesList(
                                      loadedTypes: loadedTypes,
                                      hasMore: hasMore,
                                      isPageLoading: isPageLoading,
                                    ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required String? error,
    required Widget body,
  }) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.router
              .push(
                const TenantAdminStaticProfileTypeCreateRoute(),
              )
              .then((_) => _controller.loadTypes());
        },
        icon: const Icon(Icons.add),
        label: const Text('Criar tipo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipos cadastrados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage:
                      'Não foi possível carregar os tipos de ativo.',
                  onRetry: _controller.loadTypes,
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildTypesList({
    required List<TenantAdminStaticProfileTypeDefinition> loadedTypes,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    final itemCount = loadedTypes.length + (hasMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= loadedTypes.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        final type = loadedTypes[index];
        final subtitle = _buildSubtitle(type);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(type.label),
            subtitle: Text(subtitle.isEmpty ? type.type : subtitle),
            onTap: () {
              context.router
                  .push(
                    TenantAdminStaticProfileTypeDetailRoute(
                      profileType: type.type,
                      definition: type,
                    ),
                  )
                  .then((_) => _controller.loadTypes());
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  context.router
                      .push(
                        TenantAdminStaticProfileTypeEditRoute(
                          profileType: type.type,
                          definition: type,
                        ),
                      )
                      .then((_) => _controller.loadTypes());
                }
                if (value == 'delete') {
                  await _confirmDelete(type.type, type.label);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Remover'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildSubtitle(TenantAdminStaticProfileTypeDefinition type) {
    final parts = <String>[];
    if (type.capabilities.isPoiEnabled) parts.add('POI habilitado');
    if (type.capabilities.hasBio) parts.add('Bio');
    if (type.capabilities.hasTaxonomies) parts.add('Taxonomias');
    if (type.capabilities.hasAvatar) parts.add('Avatar');
    if (type.capabilities.hasCover) parts.add('Capa');
    if (type.capabilities.hasContent) parts.add('Conteudo');
    if (type.allowedTaxonomies.isNotEmpty) {
      parts.add('Taxonomias: ${type.allowedTaxonomies.join(', ')}');
    }
    return parts.join(' - ');
  }

  void _handleSuccessMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearSuccessMessage();
    });
  }

  void _handleActionErrorMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearActionErrorMessage();
    });
  }
}
