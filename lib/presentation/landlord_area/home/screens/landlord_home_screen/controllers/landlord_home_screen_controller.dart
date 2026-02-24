import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class LandlordHomeScreenController implements Disposable {
  LandlordHomeScreenController({
    AdminModeRepositoryContract? adminModeRepository,
    LandlordAuthRepositoryContract? landlordAuthRepository,
    AppDataRepositoryContract? appDataRepository,
  })  : _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>(),
        _landlordAuthRepository = landlordAuthRepository ??
            GetIt.I.get<LandlordAuthRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>();

  final AdminModeRepositoryContract _adminModeRepository;
  final LandlordAuthRepositoryContract _landlordAuthRepository;
  final AppDataRepositoryContract _appDataRepository;

  final StreamValue<LandlordHomeUiState> uiStateStreamValue =
      StreamValue<LandlordHomeUiState>(
    defaultValue: LandlordHomeUiState.initial(),
  );

  bool get isLandlordMode => _adminModeRepository.isLandlordMode;
  bool get hasValidSession => _landlordAuthRepository.hasValidSession;
  bool get canAccessAdminArea => hasValidSession && isLandlordMode;

  Future<void> init() async {
    await _adminModeRepository.init();
    refreshUiState();
  }

  void refreshUiState() {
    uiStateStreamValue.addValue(
      LandlordHomeUiState(
        tenants: _resolveTenants(),
        hasValidSession: hasValidSession,
        isLandlordMode: isLandlordMode,
      ),
    );
  }

  List<String> _resolveTenants() {
    final tenants = <String>{};
    final landlordHost = _resolveHost(BellugaConstants.landlordDomain);

    try {
      final appData = _appDataRepository.appData;
      for (final domain in appData.domains) {
        final host = domain.value.host.trim();
        if (host.isEmpty || host == landlordHost) {
          continue;
        }
        tenants.add(host);
      }

      for (final appDomain in appData.appDomains ?? const []) {
        final normalized = _normalizeTenantLabel(appDomain.value);
        if (normalized == null || normalized == landlordHost) {
          continue;
        }
        tenants.add(normalized);
      }
    } catch (_) {
      return const [];
    }

    final sorted = tenants.toList(growable: false)..sort();
    return sorted;
  }

  String? _normalizeTenantLabel(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return value;
  }

  String? _resolveHost(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
  }

  @override
  void onDispose() {
    uiStateStreamValue.dispose();
  }
}

class LandlordHomeUiState {
  const LandlordHomeUiState({
    required this.tenants,
    required this.hasValidSession,
    required this.isLandlordMode,
  });

  factory LandlordHomeUiState.initial() => const LandlordHomeUiState(
        tenants: <String>[],
        hasValidSession: false,
        isLandlordMode: false,
      );

  final List<String> tenants;
  final bool hasValidSession;
  final bool isLandlordMode;

  bool get canAccessAdminArea => hasValidSession && isLandlordMode;
}
