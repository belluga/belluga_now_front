import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes empty groups, mixed items, and backend capabilities', () {
    final profile = TenantAdminAccountProfileDTO.fromJson({
      'id': 'profile-1',
      'account_id': 'account-1',
      'profile_type': 'venue',
      'display_name': 'Venue',
      'gallery_capabilities': {'max_galleries': 6, 'max_items_per_gallery': 12},
      'gallery_groups': [
        {'group_id': 'empty', 'subtitle': 'Empty', 'order': 0, 'items': []},
        {
          'group_id': 'mixed',
          'subtitle': 'Mixed',
          'order': 1,
          'items': [
            {
              'item_id': 'photo',
              'type': 'photo',
              'order': 0,
              'image_url': 'https://example.test/image.jpg',
              'thumb_url': 'https://example.test/thumb.jpg',
              'card_url': 'https://example.test/card.jpg',
              'modal_url': 'https://example.test/modal.jpg',
            },
            {
              'item_id': 'video',
              'type': 'youtube',
              'title': 'Um minuto na praia',
              'description': 'O caminho da pousada até o mar.',
              'order': 1,
              'youtube_video_id': 'dQw4w9WgXcQ',
              'player_aspect_ratio': 0.565,
            },
          ],
        },
      ],
    }).toDomain();

    expect(profile.galleryGroups, hasLength(2));
    expect(profile.galleryGroups.first.items, isEmpty);
    expect(profile.galleryGroups.last.items.last.type.name, 'youtube');
    expect(profile.galleryGroups.last.items.last.title, 'Um minuto na praia');
    expect(
      profile.galleryGroups.last.items.last.description,
      'O caminho da pousada até o mar.',
    );
    expect(profile.galleryGroups.last.items.last.youtubeVideoId, 'dQw4w9WgXcQ');
    expect(profile.galleryGroups.last.items.last.playerAspectRatio, 0.565);
    expect(profile.galleryCapabilities.maxGalleries, 6);
    expect(profile.galleryCapabilities.maxItemsPerGallery, 12);
  });

  test('decodes the production-shaped AGLA edit payload', () {
    final profile = TenantAdminAccountProfileDTO.fromJson({
      'id': '6a6bc34e512136a0050eabaa',
      'account_id': '6a6bc34e512136a0050eaba8',
      'profile_type': 'associacao',
      'display_name': 'AGLA',
      'slug': 'agla',
      'aggregate_revision': 1,
      'contact_mode': 'own',
      'contact_source_account_profile_id': null,
      'contact_channels': const [],
      'contact_bubble_channel_id': null,
      'effective_contact_channels': const [],
      'effective_contact_source': {
        'id': '6a6bc34e512136a0050eabaa',
        'display_name': 'AGLA',
        'profile_type': 'associacao',
        'slug': 'agla',
      },
    }).toDomain();

    expect(profile.displayName, 'AGLA');
    expect(profile.effectiveContactSourceProfile?.displayName, 'AGLA');
    expect(profile.effectiveContactSourceProfile?.profileType, 'associacao');
  });

  test('keeps the longer production-shaped Pousada edit payload valid', () {
    final profile = TenantAdminAccountProfileDTO.fromJson({
      'id': '6a8f2e97ae182af90009406c',
      'account_id': '6a8f2e97ae182af90009406a',
      'profile_type': 'hoteis-pousadas',
      'display_name': 'Pousada Camping Porto Grande',
      'slug': 'pousada-camping-porto-grande',
      'aggregate_revision': 4,
      'contact_mode': 'own',
      'contact_channels': const [],
    }).toDomain();

    expect(profile.displayName, 'Pousada Camping Porto Grande');
  });

  test('preserves linked profile ids and contact source summary', () {
    final profile = TenantAdminAccountProfileDTO.fromJson({
      'id': 'profile-parent',
      'account_id': 'account-parent',
      'profile_type': 'venue',
      'display_name': 'Parent',
      'aggregate_revision': 7,
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
    expect(nestedGroup.accountProfileIdValues.map((entry) => entry.value), [
      'profile-active',
      'profile-deleted',
    ]);
    expect(profile.contactSourceProfile?.id, '507f1f77bcf86cd799439011');
    expect(profile.contactSourceProfile?.displayName, 'Contact source');
    expect(profile.contactSourceProfile?.profileType, 'venue');
    expect(profile.contactSourceProfile?.slug, 'contact-source');
    expect(profile.aggregateRevision, 7);
  });

  test('accepts legacy nested group id aliases on readback', () {
    final profile = TenantAdminAccountProfileDTO.fromJson({
      'id': 'profile-parent',
      'account_id': 'account-parent',
      'profile_type': 'venue',
      'display_name': 'Parent',
      'nested_profile_groups': [
        {
          'group_id': 'legacy-group-id',
          'label': 'Legacy group',
          'order': 3,
          'profile_ids': ['profile-1'],
        },
      ],
    }).toDomain();

    final nestedGroup = profile.nestedProfileGroups.single;
    expect(nestedGroup.id, 'legacy-group-id');
    expect(nestedGroup.label, 'Legacy group');
    expect(nestedGroup.accountProfileIdValues.map((entry) => entry.value), [
      'profile-1',
    ]);
  });

  test('accepts aggregation nested group id alias on readback', () {
    final profile = TenantAdminAccountProfileDTO.fromJson({
      'id': 'profile-parent',
      'account_id': 'account-parent',
      'profile_type': 'venue',
      'display_name': 'Parent',
      'nested_profile_groups': [
        {
          'aggregation': 'aggregated-partners',
          'label': 'Aggregated group',
          'order': 1,
          'profile_ids': ['profile-7'],
        },
      ],
    }).toDomain();

    final nestedGroup = profile.nestedProfileGroups.single;
    expect(nestedGroup.id, 'aggregated-partners');
    expect(nestedGroup.label, 'Aggregated group');
    expect(nestedGroup.accountProfileIdValues.map((entry) => entry.value), [
      'profile-7',
    ]);
  });
}
