import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminSettingsRepositoryContract {
  static final Expando<_TenantAdminSettingsDomainsPaginationState>
      _domainsPaginationStateByRepository =
      Expando<_TenantAdminSettingsDomainsPaginationState>();
  static const int _defaultDomainsPageSizeRaw = 15;

  _TenantAdminSettingsDomainsPaginationState get _domainsPaginationState =>
      _domainsPaginationStateByRepository[this] ??=
          _TenantAdminSettingsDomainsPaginationState();

  StreamValue<List<TenantAdminDomainEntry>> get domainsStreamValue =>
      _domainsPaginationState.domainsStreamValue;

  StreamValue<bool> get hasMoreDomainsStreamValue =>
      _domainsPaginationState.hasMoreDomainsStreamValue;

  StreamValue<bool> get isDomainsPageLoadingStreamValue =>
      _domainsPaginationState.isDomainsPageLoadingStreamValue;

  StreamValue<TenantAdminBrandingSettings?> get brandingSettingsStreamValue;

  void clearBrandingSettings();

  Future<TenantAdminMapUiSettings> fetchMapUiSettings();

  Future<TenantAdminMapUiSettings> updateMapUiSettings({
    required TenantAdminMapUiSettings settings,
  });

  Future<TenantAdminDiscoveryFiltersSettingsValue>
      fetchDiscoveryFiltersSettings() {
    return Future<TenantAdminDiscoveryFiltersSettingsValue>.value(
      TenantAdminDiscoveryFiltersSettingsValue(),
    );
  }

  Future<TenantAdminDiscoveryFiltersSettingsValue>
      updateDiscoveryFiltersSettings({
    required TenantAdminDiscoveryFiltersSettingsValue settings,
  }) {
    return Future<TenantAdminDiscoveryFiltersSettingsValue>.value(settings);
  }

  Future<TenantAdminAppLinksSettings> fetchAppLinksSettings();

  Future<TenantAdminAppLinksSettings> updateAppLinksSettings({
    required TenantAdminAppLinksSettings settings,
  });

  Future<void> loadDomains() async {
    await _waitForDomainsFetch();
    _resetDomainsPagination();
    domainsStreamValue.addValue(const <TenantAdminDomainEntry>[]);
    await _fetchDomainsPage(
      page: TenantAdminCountValue(1),
      pageSize: TenantAdminCountValue(_defaultDomainsPageSizeRaw),
    );
  }

  Future<void> loadMoreDomains() async {
    if (_domainsPaginationState.isFetchingDomainsPage.value ||
        !_domainsPaginationState.hasMoreDomains.value) {
      return;
    }

    await _fetchDomainsPage(
      page: TenantAdminCountValue(
        _domainsPaginationState.currentDomainsPage.value + 1,
      ),
      pageSize: TenantAdminCountValue(_defaultDomainsPageSizeRaw),
    );
  }

  void resetDomainsState() {
    _resetDomainsPagination();
    domainsStreamValue.addValue(const <TenantAdminDomainEntry>[]);
  }

  Future<TenantAdminPagedResult<TenantAdminDomainEntry>> fetchDomainsPage({
    required TenantAdminCountValue page,
    required TenantAdminCountValue pageSize,
  });

  Future<TenantAdminDomainEntry> createDomain({
    required TenantAdminRequiredTextValue path,
  });

  Future<void> deleteDomain(
    TenantAdminRequiredTextValue domainId,
  );

  Future<String> uploadMapFilterImage({
    required TenantAdminLowercaseTokenValue key,
    required TenantAdminMediaUpload upload,
  });

  Future<TenantAdminFirebaseSettings?> fetchFirebaseSettings();

  Future<TenantAdminFirebaseSettings> updateFirebaseSettings({
    required TenantAdminFirebaseSettings settings,
  });

  Future<TenantAdminPushSettings> fetchPushSettings();

  Future<TenantAdminPushStatus> fetchPushStatus();

  Future<TenantAdminPushSettings> enablePush();

  Future<TenantAdminPushSettings> disablePush();

  Future<TenantAdminPushCredentials?> fetchPushCredentials();

  Future<TenantAdminPushCredentials> upsertPushCredentials({
    required TenantAdminPushCredentials credentials,
  });

  Future<TenantAdminResendEmailSettings> fetchResendEmailSettings();

  Future<TenantAdminResendEmailSettings> updateResendEmailSettings({
    required TenantAdminResendEmailSettings settings,
  });

  Future<TenantAdminOutboundIntegrationsSettings>
      fetchOutboundIntegrationsSettings();

  Future<TenantAdminOutboundIntegrationsSettings>
      updateOutboundIntegrationsSettings({
    required TenantAdminOutboundIntegrationsSettings settings,
  });

  Future<TenantAdminPhoneOtpReviewAccessSettings>
      fetchPhoneOtpReviewAccessSettings();

  Future<TenantAdminPhoneOtpReviewAccessSettings>
      updatePhoneOtpReviewAccessSettings({
    required TenantAdminPhoneOtpReviewAccessSettings settings,
  });

  Future<String> generatePhoneOtpReviewAccessCodeHash({
    required TenantAdminRequiredTextValue code,
  });

  Future<TenantAdminPushSettings> updatePushSettings({
    required TenantAdminPushSettings settings,
  });

  Future<TenantAdminTelemetrySettingsSnapshot> fetchTelemetrySettings();

  Future<TenantAdminTelemetrySettingsSnapshot> upsertTelemetryIntegration({
    required TenantAdminTelemetryIntegration integration,
  });

  Future<TenantAdminTelemetrySettingsSnapshot> deleteTelemetryIntegration({
    required TenantAdminLowercaseTokenValue type,
  });

  Future<TenantAdminBrandingSettings> fetchBrandingSettings();

  Future<TenantAdminBrandingSettings> updateBranding({
    required TenantAdminBrandingUpdateInput input,
  });

  Future<void> _waitForDomainsFetch() async {
    while (_domainsPaginationState.isFetchingDomainsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchDomainsPage({
    required TenantAdminCountValue page,
    required TenantAdminCountValue pageSize,
  }) async {
    if (_domainsPaginationState.isFetchingDomainsPage.value) {
      return;
    }
    if (page.value > 1 && !_domainsPaginationState.hasMoreDomains.value) {
      return;
    }

    _domainsPaginationState.isFetchingDomainsPage = TenantAdminFlagValue(true);
    if (page.value > 1) {
      isDomainsPageLoadingStreamValue.addValue(true);
    }

    try {
      final result = await fetchDomainsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _domainsPaginationState.cachedDomains
          ..clear()
          ..addAll(result.items);
      } else {
        _domainsPaginationState.cachedDomains.addAll(result.items);
      }
      _domainsPaginationState.currentDomainsPage = page;
      _domainsPaginationState.hasMoreDomains = TenantAdminFlagValue(
        result.hasMore,
      );
      hasMoreDomainsStreamValue.addValue(result.hasMore);
      domainsStreamValue.addValue(
        List<TenantAdminDomainEntry>.unmodifiable(
          _domainsPaginationState.cachedDomains,
        ),
      );
    } catch (_) {
      if (page.value == 1) {
        domainsStreamValue.addValue(const <TenantAdminDomainEntry>[]);
      }
      rethrow;
    } finally {
      _domainsPaginationState.isFetchingDomainsPage =
          TenantAdminFlagValue(false);
      isDomainsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetDomainsPagination() {
    _domainsPaginationState.cachedDomains.clear();
    _domainsPaginationState.currentDomainsPage = TenantAdminCountValue(0);
    _domainsPaginationState.hasMoreDomains = TenantAdminFlagValue(false);
    _domainsPaginationState.isFetchingDomainsPage = TenantAdminFlagValue(false);
    hasMoreDomainsStreamValue.addValue(false);
    isDomainsPageLoadingStreamValue.addValue(false);
  }
}

class _TenantAdminSettingsDomainsPaginationState {
  final List<TenantAdminDomainEntry> cachedDomains = <TenantAdminDomainEntry>[];
  final StreamValue<List<TenantAdminDomainEntry>> domainsStreamValue =
      StreamValue<List<TenantAdminDomainEntry>>(
    defaultValue: const <TenantAdminDomainEntry>[],
  );
  final StreamValue<bool> hasMoreDomainsStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> isDomainsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  TenantAdminFlagValue isFetchingDomainsPage = TenantAdminFlagValue(false);
  TenantAdminFlagValue hasMoreDomains = TenantAdminFlagValue(false);
  TenantAdminCountValue currentDomainsPage = TenantAdminCountValue(0);
}
