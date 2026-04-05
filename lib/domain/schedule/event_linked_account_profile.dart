export 'event_linked_account_profile_taxonomy_term.dart';
export 'event_linked_account_profile_taxonomy_terms.dart';

import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile_taxonomy_terms.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class EventLinkedAccountProfile {
  EventLinkedAccountProfile({
    required this.idValue,
    required this.displayNameValue,
    required this.profileTypeValue,
    required this.slugValue,
    this.avatarUrlValue,
    this.coverUrlValue,
    this.partyTypeValue,
    EventLinkedAccountProfileTaxonomyTerms? taxonomyTerms,
  }) : taxonomyTerms =
           taxonomyTerms ?? const EventLinkedAccountProfileTaxonomyTerms.empty();

  final EventLinkedAccountProfileTextValue idValue;
  final EventLinkedAccountProfileTextValue displayNameValue;
  final AccountProfileTypeValue profileTypeValue;
  final SlugValue slugValue;
  final ThumbUriValue? avatarUrlValue;
  final ThumbUriValue? coverUrlValue;
  final EventLinkedAccountProfileTextValue? partyTypeValue;
  final EventLinkedAccountProfileTaxonomyTerms taxonomyTerms;

  String get id => idValue.value;
  String get displayName => displayNameValue.value;
  String get profileType => profileTypeValue.value;
  String get slug => slugValue.value;
  String? get avatarUrl => avatarUrlValue?.value.toString();
  String? get coverUrl => coverUrlValue?.value.toString();
  String? get partyType => partyTypeValue?.value;
}
