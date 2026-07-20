import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'preserves linked profile ids and contact source summary',
    () {
      final profile = TenantAdminAccountProfileDTO.fromJson({
        'id': 'profile-parent',
        'account_id': 'account-parent',
        'profile_type': 'venue',
        'display_name': 'Parent',
        'nested_profile_groups': [
          {
            'id': 'artists',
            'label': 'Artists',
            'order': 0,
            'account_profile_ids': ['profile-active', 'profile-deleted'],
            'account_profile_summaries': [
              {
                'id': 'profile-active',
                'display_name': 'Active artist',
                'is_queryable_candidate': true,
                'is_contact_capable_candidate': false,
              },
              {
                'id': 'profile-deleted',
                'display_name': null,
                'is_queryable_candidate': false,
                'is_contact_capable_candidate': false,
              },
            ],
          },
        ],
        'contact_source_account_profile_id': '507f1f77bcf86cd799439011',
        'contact_source_account_profile': {
          'id': '507f1f77bcf86cd799439011',
          'display_name': 'Contact source',
          'profile_type': 'venue',
          'slug': 'contact-source',
        },
      }).toDomain();

      final nestedGroup = profile.nestedProfileGroups.single;
      expect(
        nestedGroup.accountProfileIdValues.map((entry) => entry.value),
        [
        'profile-active',
        'profile-deleted',
        ],
      );
      expect(profile.contactSourceProfile?.id, '507f1f77bcf86cd799439011');
      expect(profile.contactSourceProfile?.displayName, 'Contact source');
      expect(profile.contactSourceProfile?.profileType, 'venue');
      expect(profile.contactSourceProfile?.slug, 'contact-source');
    },
  );
}
