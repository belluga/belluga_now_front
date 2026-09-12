import 'package:belluga_now/domain/repositories/tenant_admin_account_profile_candidates_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_home_favorites_pinned_profile_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_home_favorites_pinned_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsRepository extends Fake
    implements TenantAdminSettingsRepositoryContract {
  _FakeSettingsRepository(
    this.initial,
    this.updated, {
    this.fetchFailuresBeforeSuccess = 0,
  });

  final TenantAdminHomeFavoritesPinnedProfileSettings initial;
  final TenantAdminHomeFavoritesPinnedProfileSettings updated;
  int fetchFailuresBeforeSuccess;
  int updateCalls = 0;
  TenantAdminAccountProfileIdValue? savedId;

  @override
  Future<TenantAdminHomeFavoritesPinnedProfileSettings>
  fetchHomeFavoritesPinnedProfile() async {
    if (fetchFailuresBeforeSuccess > 0) {
      fetchFailuresBeforeSuccess -= 1;
      throw StateError('settings unavailable');
    }
    return initial;
  }

  @override
  Future<TenantAdminHomeFavoritesPinnedProfileSettings>
  updateHomeFavoritesPinnedProfile({
    required TenantAdminAccountProfileIdValue? accountProfileId,
  }) async {
    updateCalls += 1;
    savedId = accountProfileId;
    return accountProfileId == null ? _unsetSettings() : updated;
  }
}

class _FakeCandidatesRepository extends Fake
    implements TenantAdminAccountProfileCandidatesRepositoryContract {}

void main() {
  test(
    'uses canonical single-selection picker and persists one profile id',
    () async {
      final initial = _settings('profile-1', 'Profile One');
      final updated = _settings('profile-2', 'Profile Two');
      final settingsRepository = _FakeSettingsRepository(initial, updated);
      final candidatesRepository = _FakeCandidatesRepository();
      final controller = TenantAdminHomeFavoritesPinnedProfileController(
        settingsRepository: settingsRepository,
        candidatesRepository: candidatesRepository,
      );

      await controller.init();
      final picker = controller.createPickerSession();
      controller.select(
        TenantAdminAccountProfileSelectionSummary(
          idValue: TenantAdminAccountProfileIdValue('profile-2'),
          displayNameValue: TenantAdminOptionalTextValue()
            ..parse('Profile Two'),
        ),
      );
      final saved = await controller.save();

      expect(picker.maxSelections, 1);
      expect(
        picker.scope,
        TenantAdminAccountProfileCandidateScope.homeFavoritesPinnedProfile,
      );
      expect(saved, isTrue);
      expect(settingsRepository.savedId?.value, 'profile-2');

      controller.clear();
      final cleared = await controller.save();

      expect(cleared, isTrue);
      expect(settingsRepository.savedId, isNull);
      expect(settingsRepository.updateCalls, 2);
      expect(controller.draftAccountProfileId, isNull);
      expect(controller.settingsStreamValue.value?.availability, 'unset');

      controller.disposePickerSession(picker);
      controller.onDispose();
    },
  );

  test('initial read failure cannot clear an unknown persisted value', () async {
    final settingsRepository = _FakeSettingsRepository(
      _settings('profile-1', 'Profile One'),
      _settings('profile-1', 'Profile One'),
      fetchFailuresBeforeSuccess: 1,
    );
    final controller = TenantAdminHomeFavoritesPinnedProfileController(
      settingsRepository: settingsRepository,
      candidatesRepository: _FakeCandidatesRepository(),
    );

    await controller.init();

    expect(controller.hasAuthoritativeBaseline, isFalse);
    expect(await controller.save(), isFalse);
    expect(settingsRepository.updateCalls, 0);

    await controller.init();

    expect(controller.hasAuthoritativeBaseline, isTrue);
    expect(controller.draftAccountProfileId, 'profile-1');

    controller.onDispose();
  });
}

TenantAdminHomeFavoritesPinnedProfileSettings _unsetSettings() =>
    TenantAdminHomeFavoritesPinnedProfileSettings(
      accountProfileIdValue: null,
      availabilityValue: TenantAdminLowercaseTokenValue.fromRaw('unset'),
      selectedProfileDisplayNameValue: TenantAdminOptionalTextValue(),
    );

TenantAdminHomeFavoritesPinnedProfileSettings _settings(
  String id,
  String name,
) => TenantAdminHomeFavoritesPinnedProfileSettings(
  accountProfileIdValue: TenantAdminAccountProfileIdValue(id),
  availabilityValue: TenantAdminLowercaseTokenValue.fromRaw('available'),
  selectedProfileDisplayNameValue: TenantAdminOptionalTextValue()..parse(name),
);
