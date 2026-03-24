import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_date_time_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_date_time_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_double_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

part 'tenant_admin_event/tenant_admin_event_draft.dart';
part 'tenant_admin_event/tenant_admin_event_location.dart';
part 'tenant_admin_event/tenant_admin_event_occurrence.dart';
part 'tenant_admin_event/tenant_admin_event_online_location.dart';
part 'tenant_admin_event/tenant_admin_event_party.dart';
part 'tenant_admin_event/tenant_admin_event_party_candidates.dart';
part 'tenant_admin_event/tenant_admin_event_place_ref.dart';
part 'tenant_admin_event/tenant_admin_event_publication.dart';
part 'tenant_admin_event/tenant_admin_event_type.dart';

class TenantAdminEvent {
  TenantAdminEvent({
    required Object eventId,
    required Object slug,
    required Object title,
    required Object content,
    required this.type,
    required this.occurrences,
    required this.publication,
    this.location,
    this.placeRef,
    Object? thumbUrl,
    Object? artistIds,
    this.eventParties = const <TenantAdminEventParty>[],
    this.taxonomyTerms = const <TenantAdminTaxonomyTerm>[],
    Object? createdAt,
    Object? updatedAt,
    Object? deletedAt,
  })  : eventIdValue = tenantAdminRequiredText(eventId),
        slugValue = tenantAdminRequiredText(slug),
        titleValue = tenantAdminRequiredText(title),
        contentValue = tenantAdminOptionalText(content),
        thumbUrlValue = tenantAdminOptionalUrl(thumbUrl),
        artistIdValues = tenantAdminTrimmedStringList(artistIds),
        createdAtValue = tenantAdminOptionalDateTime(createdAt),
        updatedAtValue = tenantAdminOptionalDateTime(updatedAt),
        deletedAtValue = tenantAdminOptionalDateTime(deletedAt);

  final TenantAdminRequiredTextValue eventIdValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminRequiredTextValue titleValue;
  final TenantAdminOptionalTextValue contentValue;
  final TenantAdminEventType type;
  final TenantAdminEventLocation? location;
  final TenantAdminEventPlaceRef? placeRef;
  final TenantAdminOptionalUrlValue thumbUrlValue;
  final List<TenantAdminEventOccurrence> occurrences;
  final TenantAdminEventPublication publication;
  final TenantAdminTrimmedStringListValue artistIdValues;
  final List<TenantAdminEventParty> eventParties;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
  final TenantAdminOptionalDateTimeValue createdAtValue;
  final TenantAdminOptionalDateTimeValue updatedAtValue;
  final TenantAdminOptionalDateTimeValue deletedAtValue;

  String get eventId => eventIdValue.value;
  String get slug => slugValue.value;
  String get title => titleValue.value;
  String get content => contentValue.value;
  String? get thumbUrl => thumbUrlValue.nullableValue;
  List<String> get artistIds => artistIdValues.value;
  DateTime? get createdAt => createdAtValue.value;
  DateTime? get updatedAt => updatedAtValue.value;
  DateTime? get deletedAt => deletedAtValue.value;
}
