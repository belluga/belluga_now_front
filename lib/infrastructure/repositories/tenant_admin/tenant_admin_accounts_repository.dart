import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminAccountsRepository
    implements TenantAdminAccountsRepositoryContract {
  TenantAdminAccountsRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;

  String get _apiBaseUrl =>
      (_tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>())
          .selectedTenantAdminBaseUrl;

  Map<String, String> _buildHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/accounts',
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      return data.map(_mapAccount).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load accounts');
    }
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/accounts/$accountSlug',
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapAccount(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'load account');
    }
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    required TenantAdminDocument document,
    String? organizationId,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/accounts',
        data: {
          'name': name,
          'document': {
            'type': document.type,
            'number': document.number,
          },
          if (organizationId != null && organizationId.trim().isNotEmpty)
            'organization_id': organizationId.trim(),
        },
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractAccountFromCreate(response.data);
      return _mapAccount(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'create account');
    }
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    TenantAdminDocument? document,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }
      if (document != null) {
        payload['document'] = {
          'type': document.type,
          'number': document.number,
        };
      }
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/accounts/$accountSlug',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapAccount(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'update account');
    }
  }

  @override
  Future<void> deleteAccount(String accountSlug) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/accounts/$accountSlug',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete account');
    }
  }

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/accounts/$accountSlug/restore',
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapAccount(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'restore account');
    }
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {
    try {
      await _dio.post(
        '$_apiBaseUrl/v1/accounts/$accountSlug/force_delete',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'force delete account');
    }
  }

  Map<String, dynamic> _extractItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    throw Exception('Unexpected account response shape.');
  }

  Map<String, dynamic> _extractAccountFromCreate(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final account = data['account'];
        if (account is Map<String, dynamic>) {
          return account;
        }
        return data;
      }
    }
    throw Exception('Unexpected account create response shape.');
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    throw Exception('Unexpected accounts list response shape.');
  }

  TenantAdminAccount _mapAccount(Map<String, dynamic> json) {
    final dto = TenantAdminAccountDTO.fromJson(json);
    return TenantAdminAccount(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      document: TenantAdminDocument(
        type: dto.documentType,
        number: dto.documentNumber,
      ),
      organizationId: dto.organizationId,
      ownershipState:
          TenantAdminOwnershipState.fromApiValue(dto.ownershipState),
    );
  }

  Exception _wrapError(DioException error, String label) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    return Exception(
      'Failed to $label [status=$status] (${error.requestOptions.uri}): '
      '${data ?? error.message}',
    );
  }
}
