import 'package:belluga_form_validation/belluga_form_validation.dart';

abstract final class TenantAdminEventFormValidationTargets {
  static const String global = 'global';
  static const String title = 'title';
  static const String eventType = 'event_type';
  static const String schedule = 'schedule';
  static const String publication = 'publication';
  static const String location = 'location';
  static const String relatedProfiles = 'related_profiles';
  static const String taxonomies = 'taxonomies';
}

final tenantAdminEventFormValidationConfig = FormValidationConfig(
  formId: 'tenant_admin_event_form',
  bindings: <FormValidationBinding>[
    globalAny(const <String>[
      'event',
    ], targetId: TenantAdminEventFormValidationTargets.global),
    field('title', targetId: TenantAdminEventFormValidationTargets.title),
    fieldAny(const <String>[
      'type',
      'type.id',
      'type.slug',
    ], targetId: TenantAdminEventFormValidationTargets.eventType),
    group(
      'occurrences',
      targetId: TenantAdminEventFormValidationTargets.schedule,
    ),
    groupPattern(
      'occurrences.*',
      targetId: TenantAdminEventFormValidationTargets.schedule,
    ),
    groupPattern(
      'occurrences.*.*',
      targetId: TenantAdminEventFormValidationTargets.schedule,
    ),
    groupPattern(
      'occurrences.*.*.*',
      targetId: TenantAdminEventFormValidationTargets.schedule,
    ),
    groupPattern(
      'occurrences.*.*.*.*',
      targetId: TenantAdminEventFormValidationTargets.schedule,
    ),
    groupPattern(
      'occurrences.*.*.*.*.*',
      targetId: TenantAdminEventFormValidationTargets.schedule,
    ),
    groupPattern(
      'occurrences.*.date_time_start',
      targetId: TenantAdminEventFormValidationTargets.schedule,
    ),
    groupPattern(
      'occurrences.*.date_time_end',
      targetId: TenantAdminEventFormValidationTargets.schedule,
    ),
    groupAny(const <String>[
      'publication',
      'publication.publish_at',
    ], targetId: TenantAdminEventFormValidationTargets.publication),
    group('location', targetId: TenantAdminEventFormValidationTargets.location),
    groupPattern(
      'location.*',
      targetId: TenantAdminEventFormValidationTargets.location,
    ),
    groupPattern(
      'location.*.*',
      targetId: TenantAdminEventFormValidationTargets.location,
    ),
    groupPattern(
      'location.*.*.*',
      targetId: TenantAdminEventFormValidationTargets.location,
    ),
    group(
      'place_ref',
      targetId: TenantAdminEventFormValidationTargets.location,
    ),
    groupPattern(
      'place_ref.*',
      targetId: TenantAdminEventFormValidationTargets.location,
    ),
    groupAny(const <String>[
      'event_parties',
      'profile_groups',
    ], targetId: TenantAdminEventFormValidationTargets.relatedProfiles),
    groupPattern(
      'event_parties.*',
      targetId: TenantAdminEventFormValidationTargets.relatedProfiles,
    ),
    groupPattern(
      'event_parties.*.*',
      targetId: TenantAdminEventFormValidationTargets.relatedProfiles,
    ),
    groupPattern(
      'event_parties.*.*.*',
      targetId: TenantAdminEventFormValidationTargets.relatedProfiles,
    ),
    groupPattern(
      'profile_groups.*',
      targetId: TenantAdminEventFormValidationTargets.relatedProfiles,
    ),
    groupPattern(
      'profile_groups.*.*',
      targetId: TenantAdminEventFormValidationTargets.relatedProfiles,
    ),
    groupPattern(
      'profile_groups.*.*.*',
      targetId: TenantAdminEventFormValidationTargets.relatedProfiles,
    ),
    groupAny(const <String>[
      'tags',
      'categories',
      'taxonomy_terms',
    ], targetId: TenantAdminEventFormValidationTargets.taxonomies),
    groupPattern(
      'taxonomy_terms.*',
      targetId: TenantAdminEventFormValidationTargets.taxonomies,
    ),
    groupPattern(
      'taxonomy_terms.*.*',
      targetId: TenantAdminEventFormValidationTargets.taxonomies,
    ),
  ],
);
