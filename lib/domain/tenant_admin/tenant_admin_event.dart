import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_date_time_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_date_time_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_double_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

part 'tenant_admin_event/tenant_admin_event_draft.dart';
part 'tenant_admin_event/tenant_admin_event_location.dart';
part 'tenant_admin_event/tenant_admin_event_occurrence.dart';
part 'tenant_admin_event/tenant_admin_event_online_location.dart';
part 'tenant_admin_event/tenant_admin_event_party.dart';
part 'tenant_admin_event/tenant_admin_event_place_ref.dart';
part 'tenant_admin_event/tenant_admin_event_publication.dart';
part 'tenant_admin_event/tenant_admin_event_type.dart';

class TenantAdminEvent {
  TenantAdminEvent({
    required this.eventIdValue,
    required this.slugValue,
    required this.titleValue,
    required this.contentValue,
    required this.type,
    required this.occurrences,
    required this.publication,
    this.location,
    this.placeRef,
    TenantAdminOptionalUrlValue? thumbUrlValue,
    TenantAdminOptionalTextValue? venueDisplayNameValue,
    List<TenantAdminAccountProfileIdValue>? relatedAccountProfileIdValues,
    this.relatedAccountProfiles = const <TenantAdminAccountProfile>[],
    this.eventParties = const <TenantAdminEventParty>[],
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminOptionalDateTimeValue? createdAtValue,
    TenantAdminOptionalDateTimeValue? updatedAtValue,
    TenantAdminOptionalDateTimeValue? deletedAtValue,
  })  : thumbUrlValue = thumbUrlValue ?? TenantAdminOptionalUrlValue(),
        venueDisplayNameValue =
            venueDisplayNameValue ?? TenantAdminOptionalTextValue(),
        relatedAccountProfileIdValues =
            List<TenantAdminAccountProfileIdValue>.unmodifiable(
          relatedAccountProfileIdValues ??
              const <TenantAdminAccountProfileIdValue>[],
        ),
        createdAtValue =
            createdAtValue ?? TenantAdminOptionalDateTimeValue(null),
        updatedAtValue =
            updatedAtValue ?? TenantAdminOptionalDateTimeValue(null),
        deletedAtValue =
            deletedAtValue ?? TenantAdminOptionalDateTimeValue(null),
        taxonomyTerms = taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty();

  final TenantAdminRequiredTextValue eventIdValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminRequiredTextValue titleValue;
  final TenantAdminOptionalTextValue contentValue;
  final TenantAdminEventType type;
  final TenantAdminEventLocation? location;
  final TenantAdminEventPlaceRef? placeRef;
  final TenantAdminOptionalUrlValue thumbUrlValue;
  final TenantAdminOptionalTextValue venueDisplayNameValue;
  final List<TenantAdminEventOccurrence> occurrences;
  final TenantAdminEventPublication publication;
  final List<TenantAdminAccountProfileIdValue> relatedAccountProfileIdValues;
  final List<TenantAdminAccountProfile> relatedAccountProfiles;
  final List<TenantAdminEventParty> eventParties;
  final TenantAdminTaxonomyTerms taxonomyTerms;
  final TenantAdminOptionalDateTimeValue createdAtValue;
  final TenantAdminOptionalDateTimeValue updatedAtValue;
  final TenantAdminOptionalDateTimeValue deletedAtValue;

  String get eventId => eventIdValue.value;
  String get slug => slugValue.value;
  String get title => titleValue.value;
  String get content => contentValue.value;
  String? get thumbUrl => thumbUrlValue.nullableValue;
  String? get venueDisplayName => venueDisplayNameValue.nullableValue;
  List<TenantAdminAccountProfileIdValue> get relatedAccountProfileIds =>
      relatedAccountProfileIdValues;
  DateTime? get createdAt => createdAtValue.value;
  DateTime? get updatedAt => updatedAtValue.value;
  DateTime? get deletedAt => deletedAtValue.value;
}
