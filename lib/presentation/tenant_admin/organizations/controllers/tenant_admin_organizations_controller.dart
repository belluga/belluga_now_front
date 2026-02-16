import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminOrganizationsController implements Disposable {
  TenantAdminOrganizationsController({
    TenantAdminOrganizationsRepositoryContract? organizationsRepository,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _organizationsRepository = organizationsRepository ??
            GetIt.I.get<TenantAdminOrganizationsRepositoryContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null) {
    _bindTenantScope();
  }

  final TenantAdminOrganizationsRepositoryContract _organizationsRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  static const int _organizationsPageSize = 20;

  final StreamValue<List<TenantAdminOrganization>?> organizationsStreamValue =
      StreamValue<List<TenantAdminOrganization>?>();
  final StreamValue<bool> hasMoreOrganizationsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isOrganizationsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<TenantAdminOrganization?> organizationDetailStreamValue =
      StreamValue<TenantAdminOrganization?>();
  final StreamValue<bool> organizationDetailLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> organizationDetailErrorStreamValue =
      StreamValue<String?>();
  final StreamValue<bool> organizationUpdatingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> createSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> createSuccessMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> createErrorMessageStreamValue =
      StreamValue<String?>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _isDisposed = false;
  bool _isFetchingOrganizationsPage = false;
  bool _hasMoreOrganizations = true;
  int _currentOrganizationsPage = 0;
  final List<TenantAdminOrganization> _fetchedOrganizations =
      <TenantAdminOrganization>[];
  StreamSubscription<String?>? _tenantScopeSubscription;
  String? _lastTenantDomain;

  void _bindTenantScope() {
    if (_tenantScopeSubscription != null || _tenantScope == null) {
      return;
    }
    final tenantScope = _tenantScope;
    _lastTenantDomain =
        _normalizeTenantDomain(tenantScope.selectedTenantDomain);
    _tenantScopeSubscription =
        tenantScope.selectedTenantDomainStreamValue.stream.listen(
      (tenantDomain) {
        if (_isDisposed) return;
        final normalized = _normalizeTenantDomain(tenantDomain);
        if (normalized == _lastTenantDomain) {
          return;
        }
        _lastTenantDomain = normalized;
        _resetTenantScopedState();
        if (normalized != null) {
          unawaited(loadOrganizations());
        }
      },
    );
  }

  Future<void> loadOrganizations() async {
    await _waitForOrganizationsFetch();
    _resetOrganizationsPagination();
    organizationsStreamValue.addValue(null);
    await _fetchOrganizationsPage(page: 1);
  }

  Future<void> loadNextOrganizationsPage() async {
    if (_isDisposed || _isFetchingOrganizationsPage || !_hasMoreOrganizations) {
      return;
    }
    await _fetchOrganizationsPage(page: _currentOrganizationsPage + 1);
  }

  Future<void> _waitForOrganizationsFetch() async {
    while (_isFetchingOrganizationsPage && !_isDisposed) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchOrganizationsPage({required int page}) async {
    if (_isFetchingOrganizationsPage) return;
    if (page > 1 && !_hasMoreOrganizations) return;

    _isFetchingOrganizationsPage = true;
    if (page > 1 && !_isDisposed) {
      isOrganizationsPageLoadingStreamValue.addValue(true);
    }
    isLoadingStreamValue.addValue(true);
    try {
      final result = await _organizationsRepository.fetchOrganizationsPage(
        page: page,
        pageSize: _organizationsPageSize,
      );
      if (_isDisposed) return;
      if (page == 1) {
        _fetchedOrganizations
          ..clear()
          ..addAll(result.items);
      } else {
        _fetchedOrganizations.addAll(result.items);
      }
      _currentOrganizationsPage = page;
      _hasMoreOrganizations = result.hasMore;
      hasMoreOrganizationsStreamValue.addValue(_hasMoreOrganizations);
      organizationsStreamValue.addValue(
        List<TenantAdminOrganization>.unmodifiable(_fetchedOrganizations),
      );
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      organizationsStreamValue.addValue(const <TenantAdminOrganization>[]);
      errorStreamValue.addValue(error.toString());
    } finally {
      _isFetchingOrganizationsPage = false;
      if (!_isDisposed) {
        isLoadingStreamValue.addValue(false);
        isOrganizationsPageLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminOrganization> createOrganization({
    required String name,
    String? description,
  }) async {
    final org = await _organizationsRepository.createOrganization(
      name: name,
      description: description,
    );
    await loadOrganizations();
    resetCreateForm();
    return org;
  }

  Future<void> loadOrganizationDetail(String organizationId) async {
    organizationDetailLoadingStreamValue.addValue(true);
    organizationDetailErrorStreamValue.addValue(null);
    try {
      final organization =
          await _organizationsRepository.fetchOrganization(organizationId);
      if (_isDisposed) return;
      organizationDetailStreamValue.addValue(organization);
    } catch (error) {
      if (_isDisposed) return;
      organizationDetailErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        organizationDetailLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminOrganization?> updateOrganization({
    required String organizationId,
    String? name,
    String? slug,
    String? description,
  }) async {
    organizationUpdatingStreamValue.addValue(true);
    try {
      final updated = await _organizationsRepository.updateOrganization(
        organizationId: organizationId,
        name: name,
        slug: slug,
        description: description,
      );
      if (_isDisposed) {
        return null;
      }
      organizationDetailStreamValue.addValue(updated);
      organizationDetailErrorStreamValue.addValue(null);
      return updated;
    } catch (error) {
      if (_isDisposed) {
        return null;
      }
      organizationDetailErrorStreamValue.addValue(error.toString());
      return null;
    } finally {
      if (!_isDisposed) {
        organizationUpdatingStreamValue.addValue(false);
      }
    }
  }

  Future<void> submitCreateOrganization({
    required String name,
    String? description,
  }) async {
    createSubmittingStreamValue.addValue(true);
    try {
      await createOrganization(name: name, description: description);
      if (_isDisposed) return;
      createErrorMessageStreamValue.addValue(null);
      createSuccessMessageStreamValue.addValue('Organizacao salva.');
    } catch (error) {
      if (_isDisposed) return;
      createErrorMessageStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        createSubmittingStreamValue.addValue(false);
      }
    }
  }

  void clearCreateSuccessMessage() {
    createSuccessMessageStreamValue.addValue(null);
  }

  void clearCreateErrorMessage() {
    createErrorMessageStreamValue.addValue(null);
  }

  void resetCreateForm() {
    nameController.clear();
    descriptionController.clear();
  }

  void _resetTenantScopedState() {
    _resetOrganizationsPagination();
    organizationsStreamValue.addValue(null);
    errorStreamValue.addValue(null);
    createSuccessMessageStreamValue.addValue(null);
    createErrorMessageStreamValue.addValue(null);
    organizationDetailStreamValue.addValue(null);
    organizationDetailErrorStreamValue.addValue(null);
    organizationDetailLoadingStreamValue.addValue(false);
    organizationUpdatingStreamValue.addValue(false);
    resetCreateForm();
  }

  void _resetOrganizationsPagination() {
    _fetchedOrganizations.clear();
    _currentOrganizationsPage = 0;
    _hasMoreOrganizations = true;
    _isFetchingOrganizationsPage = false;
    hasMoreOrganizationsStreamValue.addValue(true);
    isOrganizationsPageLoadingStreamValue.addValue(false);
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
  }

  void dispose() {
    _isDisposed = true;
    _tenantScopeSubscription?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    organizationsStreamValue.dispose();
    hasMoreOrganizationsStreamValue.dispose();
    isOrganizationsPageLoadingStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    organizationDetailStreamValue.dispose();
    organizationDetailLoadingStreamValue.dispose();
    organizationDetailErrorStreamValue.dispose();
    organizationUpdatingStreamValue.dispose();
    createSubmittingStreamValue.dispose();
    createSuccessMessageStreamValue.dispose();
    createErrorMessageStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
