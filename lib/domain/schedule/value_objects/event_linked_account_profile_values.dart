import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

EventLinkedAccountProfile eventLinkedAccountProfileFromRaw({
  required String id,
  required String displayName,
  required String profileType,
  String? slug,
  String? avatarUrl,
  String? coverUrl,
  String? partyType,
  List<EventLinkedAccountProfileTaxonomyTerm> taxonomyTerms = const [],
}) {
  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(displayName),
    profileTypeValue: AccountProfileTypeValue(profileType),
    slugValue: _slugValueOrNull(slug),
    avatarUrlValue: _thumbUriValueOrNull(avatarUrl),
    coverUrlValue: _thumbUriValueOrNull(coverUrl),
    partyTypeValue: _textValueOrNull(partyType),
    taxonomyTerms: taxonomyTerms,
  );
}

EventLinkedAccountProfileTaxonomyTerm
eventLinkedAccountProfileTaxonomyTermFromRaw({
  required String type,
  required String value,
  String name = '',
}) {
  return EventLinkedAccountProfileTaxonomyTerm(
    typeValue: AccountProfileTagValue(type),
    valueValue: AccountProfileTagValue(value),
    nameValue: AccountProfileTagValue(name),
  );
}

EventLinkedAccountProfileTextValue? _textValueOrNull(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return EventLinkedAccountProfileTextValue(normalized);
}

SlugValue? _slugValueOrNull(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return SlugValue()..parse(normalized);
}

ThumbUriValue? _thumbUriValueOrNull(String? rawUrl) {
  final normalized = rawUrl?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final parsed = Uri.tryParse(normalized);
  if (parsed == null) {
    return null;
  }
  return ThumbUriValue(defaultValue: parsed, isRequired: true)..parse(normalized);
}
