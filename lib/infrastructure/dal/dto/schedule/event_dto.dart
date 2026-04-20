import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/thumb_dto.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class EventDTO {
  const EventDTO({
    required this.id,
    required this.slug,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    this.venue,
    this.latitude,
    this.longitude,
    this.thumb,
    required this.dateTimeStart,
    this.dateTimeEnd,
    this.artists = const [],
    this.linkedAccountProfiles = const [],
    this.isConfirmed = false,
    this.totalConfirmed = 0,
    this.receivedInvites,
    this.sentInvites,
    this.friendsGoing,
    this.tags = const [],
  });

  final String id;
  final String slug;
  final EventTypeDTO type;
  final String title;
  final String content;
  final String location;
  final Map<String, dynamic>? venue;
  final double? latitude;
  final double? longitude;
  final ThumbDTO? thumb;
  final String dateTimeStart;
  final String? dateTimeEnd;
  final List<EventArtistDTO> artists;
  final List<EventLinkedAccountProfile> linkedAccountProfiles;
  final bool isConfirmed;
  final int totalConfirmed;
  final List<Map<String, dynamic>>? receivedInvites;
  final List<Map<String, dynamic>>? sentInvites;
  final List<Map<String, dynamic>>? friendsGoing;
  final List<String> tags;

  factory EventDTO.fromJson(Map<String, dynamic> json) {
    final typePayload = _asMap(json['type']);
    final venuePayload = _asMap(json['venue']);
    final locationPayload = _asMap(json['location']);
    final geoLocationPayload = _asMap(json['geo_location']);
    final location = _resolveLocation(
      rawLocation: json['location'],
      venuePayload: venuePayload,
    );
    final coordinates = _resolveCoordinates(
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      locationPayload: locationPayload,
      geoLocationPayload: geoLocationPayload,
    );
    final linkedProfiles = _resolveLinkedAccountProfiles(
      linkedProfilesRaw: json['linked_account_profiles'],
    );
    final legacyLinkedProfiles = linkedProfiles.isNotEmpty
        ? linkedProfiles
        : _resolveLegacyArtists(
            json['artists'],
          );

    return EventDTO(
      id: _asString(json['id']) ??
          _asString(json['event_id']) ??
          _asString(json['occurrence_id']) ??
          '',
      slug: _asString(json['slug']) ?? '',
      type: EventTypeDTO(
        id: _asString(typePayload['id']) ?? '',
        name: _asString(typePayload['name']) ?? '',
        slug: _asString(typePayload['slug']) ?? '',
        description: _asString(typePayload['description']) ?? '',
        icon: _asNullableString(typePayload['icon']),
        color: _asNullableString(typePayload['color']),
      ),
      title: _asString(json['title']) ?? '',
      content: _asString(json['content']) ?? '',
      venue: venuePayload.isEmpty ? null : venuePayload,
      location: location,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      thumb: _asMap(json['thumb']).isNotEmpty
          ? ThumbDTO.fromJson(_asMap(json['thumb']))
          : null,
      dateTimeStart: _asString(json['date_time_start']) ??
          _asString(json['starts_at']) ??
          _asString(json['start_time']) ??
          '',
      dateTimeEnd: _asNullableString(json['date_time_end']) ??
          _asNullableString(json['ends_at']) ??
          _asNullableString(json['end_time']),
      linkedAccountProfiles: legacyLinkedProfiles,
      isConfirmed: _asBool(json['is_confirmed']),
      totalConfirmed: _asInt(json['total_confirmed']),
      receivedInvites: _asMapList(json['received_invites']),
      sentInvites: _asMapList(json['sent_invites']),
      friendsGoing: _asMapList(json['friends_going']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }

  EventModel toDomain() {
    final thumbDomain = thumb?.toDomain();
    final coordinate = (latitude != null && longitude != null)
        ? CityCoordinate(
            latitudeValue: LatitudeValue()..parse(latitude!.toString()),
            longitudeValue: LongitudeValue()..parse(longitude!.toString()),
          )
        : null;
    final venueDomain = venue != null ? _mapPartnerResume(venue!) : null;

    final receivedInvitesDomain = receivedInvites?.map((entry) {
      final inviteMap = Map<String, dynamic>.from(entry);
      inviteMap.putIfAbsent('event_id', () => id);
      return InviteDto.fromJson(inviteMap).toDomain();
    }).toList(growable: false);

    final sentInvitesDomain =
        sentInvites?.map(_mapSentInviteStatus).toList(growable: false);
    final friendsGoingDomain =
        friendsGoing?.map(_mapEventFriendResume).toList(growable: false);

    return eventModelFromRaw(
      id: MongoIDValue()..parse(id),
      slugValue: SlugValue()..parse(slug),
      type: EventTypeModel(
        id: EventTypeIdValue()..parse(type.id),
        name: TitleValue(minLenght: 1)..parse(type.name),
        slug: SlugValue()..parse(type.slug),
        description: DescriptionValue(minLenght: 0)..parse(type.description),
        icon: SlugValue()..parse(type.icon ?? 'default-icon'),
        color: ColorValue(defaultValue: const Color(0xFF000000))
          ..parse(type.color ?? '#000000'),
      ),
      title: TitleValue()..parse(title),
      content: HTMLContentValue(minLenght: 0)..parse(content),
      location: DescriptionValue(minLenght: 1)..parse(location),
      thumb: thumbDomain,
      dateTimeStart: DateTimeValue()..parse(dateTimeStart),
      dateTimeEnd:
          dateTimeEnd != null ? (DateTimeValue()..parse(dateTimeEnd!)) : null,
      venue: venueDomain,
      linkedAccountProfiles: linkedAccountProfiles,
      coordinate: coordinate,
      tags: tags,
      isConfirmedValue: EventIsConfirmedValue()..parse(isConfirmed.toString()),
      totalConfirmedValue: EventTotalConfirmedValue()
        ..parse(totalConfirmed.toString()),
      receivedInvites: receivedInvitesDomain,
      sentInvites: sentInvitesDomain,
      friendsGoing: friendsGoingDomain,
    );
  }

  static List<EventLinkedAccountProfile> _resolveLegacyArtists(Object? raw) {
    if (raw is! List) {
      return const [];
    }

    final resolved = <EventLinkedAccountProfile>[];
    for (final entry in raw) {
      final artist = _asMap(entry);
      final id = _asString(artist['id'])?.trim() ?? '';
      final displayName = _asString(artist['display_name'])?.trim() ??
          _asString(artist['name'])?.trim() ??
          '';
      if (id.isEmpty || displayName.isEmpty) {
        continue;
      }

      final taxonomyTerms = EventLinkedAccountProfileTaxonomyTerms();
      final genres = artist['genres'];
      if (genres is List) {
        for (final genre in genres) {
          final value = _asString(genre)?.trim() ?? '';
          if (value.isEmpty) continue;
          taxonomyTerms.addTerm(
            typeValue: AccountProfileTagValue('genre'),
            valueValue: AccountProfileTagValue(value),
            nameValue: AccountProfileTagValue(value),
          );
        }
      }

      resolved.add(
        EventLinkedAccountProfile(
          idValue: EventLinkedAccountProfileTextValue(id),
          displayNameValue: EventLinkedAccountProfileTextValue(displayName),
          profileTypeValue: AccountProfileTypeValue(
              _asString(artist['profile_type']) ?? 'artist'),
          slugValue: _requiredLinkedAccountProfileSlugValue(
            profile: artist,
            id: id,
          ),
          avatarUrlValue: _thumbUriValueOrNull(
            _asNullableString(artist['avatar_url']),
          ),
          coverUrlValue: _thumbUriValueOrNull(
            _asNullableString(artist['cover_url'] ?? artist['hero_image_url']),
          ),
          partyTypeValue: _textValueOrNull(
            _asNullableString(artist['party_type']),
          ),
          taxonomyTerms: taxonomyTerms,
        ),
      );
    }

    return List<EventLinkedAccountProfile>.unmodifiable(resolved);
  }

  DateTime? dateOnly() {
    final parsed = DateTime.tryParse(dateTimeStart);
    if (parsed == null) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  static List<EventLinkedAccountProfile> _resolveLinkedAccountProfiles({
    required Object? linkedProfilesRaw,
  }) {
    final orderedIds = <String>[];
    final mergedProfiles = <String, Map<String, dynamic>>{};

    void addProfile(Map<String, dynamic> profile) {
      final id = _asString(profile['id'])?.trim() ?? '';
      if (id.isEmpty) {
        return;
      }

      final displayName = _asString(profile['display_name'])?.trim() ??
          _asString(profile['name'])?.trim() ??
          '';
      if (displayName.isEmpty) {
        return;
      }

      final existing = mergedProfiles[id];
      if (existing == null) {
        orderedIds.add(id);
        mergedProfiles[id] = Map<String, dynamic>.from(profile);
        return;
      }

      existing['display_name'] = _preferNonEmptyString(
        existing['display_name'],
        profile['display_name'] ?? profile['name'],
      );
      existing['name'] = _preferNonEmptyString(
        existing['name'],
        profile['name'],
      );
      existing['profile_type'] = _preferNonEmptyString(
        existing['profile_type'],
        profile['profile_type'],
      );
      existing['party_type'] = _preferNonEmptyString(
        existing['party_type'],
        profile['party_type'],
      );
      existing['slug'] = _preferNonEmptyString(
        existing['slug'],
        _extractProfileSlug(profile),
      );
      existing['avatar_url'] = _preferNonEmptyString(
        existing['avatar_url'],
        profile['avatar_url'] ?? profile['logo_url'],
      );
      existing['logo_url'] = _preferNonEmptyString(
        existing['logo_url'],
        profile['logo_url'],
      );
      existing['cover_url'] = _preferNonEmptyString(
        existing['cover_url'],
        profile['cover_url'] ?? profile['hero_image_url'],
      );
      existing['hero_image_url'] = _preferNonEmptyString(
        existing['hero_image_url'],
        profile['hero_image_url'],
      );
      existing['taxonomy_terms'] = _mergeTaxonomyTerms(
        existing['taxonomy_terms'],
        profile['taxonomy_terms'],
      );
    }

    if (linkedProfilesRaw is List) {
      for (final entry in linkedProfilesRaw) {
        addProfile(_asMap(entry));
      }
    }

    final resolved = orderedIds
        .map((id) => _toLinkedAccountProfile(mergedProfiles[id]!))
        .whereType<EventLinkedAccountProfile>()
        .toList(growable: false);

    return List<EventLinkedAccountProfile>.unmodifiable(resolved);
  }

  static EventLinkedAccountProfile? _toLinkedAccountProfile(
    Map<String, dynamic> profile,
  ) {
    final id = _asString(profile['id'])?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }

    final displayName = _asString(profile['display_name'])?.trim() ??
        _asString(profile['name'])?.trim() ??
        '';
    if (displayName.isEmpty) {
      return null;
    }

    final taxonomyTermsRaw = profile['taxonomy_terms'];
    final taxonomyTerms = EventLinkedAccountProfileTaxonomyTerms();
    if (taxonomyTermsRaw is List) {
      for (final entry in taxonomyTermsRaw) {
        final term = _asMap(entry);
        final type = _asString(term['type'])?.trim() ?? '';
        final value = _asString(term['value'])?.trim() ?? '';
        if (type.isEmpty || value.isEmpty) {
          continue;
        }
        taxonomyTerms.addTerm(
          typeValue: AccountProfileTagValue(type),
          valueValue: AccountProfileTagValue(value),
          nameValue: AccountProfileTagValue(
            _asString(term['name'])?.trim() ??
                _asString(term['label'])?.trim() ??
                '',
          ),
        );
      }
    }

    final profileType =
        _asString(profile['profile_type'])?.trim().isNotEmpty == true
            ? _asString(profile['profile_type'])!.trim()
            : (_asString(profile['party_type'])?.trim() ?? '');

    return EventLinkedAccountProfile(
      idValue: EventLinkedAccountProfileTextValue(id),
      displayNameValue: EventLinkedAccountProfileTextValue(displayName),
      profileTypeValue: AccountProfileTypeValue(profileType),
      slugValue:
          _requiredLinkedAccountProfileSlugValue(profile: profile, id: id),
      avatarUrlValue: _thumbUriValueOrNull(
        _asNullableString(profile['avatar_url'] ?? profile['logo_url']),
      ),
      coverUrlValue: _thumbUriValueOrNull(
        _asNullableString(profile['cover_url'] ?? profile['hero_image_url']),
      ),
      partyTypeValue:
          _textValueOrNull(_asNullableString(profile['party_type'])),
      taxonomyTerms: taxonomyTerms,
    );
  }

  static dynamic _preferNonEmptyString(dynamic current, dynamic candidate) {
    final currentValue = _asString(current)?.trim() ?? '';
    if (currentValue.isNotEmpty) {
      return current;
    }
    final candidateValue = _asString(candidate)?.trim() ?? '';
    return candidateValue.isNotEmpty ? candidate : current;
  }

  static dynamic _extractProfileSlug(Map<String, dynamic> profile) {
    return profile['slug'] ??
        profile['account_profile_slug'] ??
        profile['profile_slug'];
  }

  static SlugValue _requiredLinkedAccountProfileSlugValue({
    required Map<String, dynamic> profile,
    required String id,
  }) {
    final slug = _asNullableString(_extractProfileSlug(profile))?.trim() ?? '';
    if (slug.isEmpty) {
      throw FormatException(
        'linked_account_profiles[$id].slug is required for route-driven navigation',
      );
    }
    return SlugValue()..parse(slug);
  }

  static EventLinkedAccountProfileTextValue? _textValueOrNull(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return EventLinkedAccountProfileTextValue(normalized);
  }

  static ThumbUriValue? _thumbUriValueOrNull(String? rawUrl) {
    final normalized = rawUrl?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(normalized);
    if (parsed == null) {
      return null;
    }
    return ThumbUriValue(defaultValue: parsed, isRequired: true)
      ..parse(normalized);
  }

  static List<Map<String, dynamic>> _mergeTaxonomyTerms(
    dynamic currentRaw,
    dynamic candidateRaw,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    void ingest(dynamic raw) {
      if (raw is! List) {
        return;
      }
      for (final entry in raw) {
        final term = _asMap(entry);
        final type = _asString(term['type'])?.trim() ?? '';
        final value = _asString(term['value'])?.trim() ?? '';
        if (type.isEmpty || value.isEmpty) {
          continue;
        }
        final key = '$type::$value';
        final existing = merged[key];
        if (existing == null) {
          merged[key] = Map<String, dynamic>.from(term);
          continue;
        }
        existing['name'] =
            _preferNonEmptyString(existing['name'], term['name']);
        existing['label'] =
            _preferNonEmptyString(existing['label'], term['label']);
      }
    }

    ingest(currentRaw);
    ingest(candidateRaw);

    return merged.values.toList(growable: false);
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static List<Map<String, dynamic>>? _asMapList(dynamic value) {
    if (value is! List) {
      return null;
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _resolveLocation({
    required dynamic rawLocation,
    required Map<String, dynamic> venuePayload,
  }) {
    final locationAsString = _asString(rawLocation);
    if (locationAsString != null) {
      return locationAsString;
    }

    final locationMap = _asMap(rawLocation);
    final locationFromMap = _asString(locationMap['display_name']) ??
        _asString(locationMap['name']) ??
        _asString(locationMap['label']) ??
        _asString(locationMap['address']) ??
        _asString(locationMap['address_line']);
    if (locationFromMap != null) {
      return locationFromMap;
    }

    return _asString(venuePayload['display_name']) ??
        _asString(venuePayload['name']) ??
        '';
  }

  static ({double? latitude, double? longitude}) _resolveCoordinates({
    required double? latitude,
    required double? longitude,
    required Map<String, dynamic> locationPayload,
    required Map<String, dynamic> geoLocationPayload,
  }) {
    if (latitude != null && longitude != null) {
      return (latitude: latitude, longitude: longitude);
    }

    final locationGeo = _asMap(locationPayload['geo']);
    final geoSource = locationGeo.isNotEmpty ? locationGeo : geoLocationPayload;
    final coordinates = geoSource['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final lng = _asDouble(coordinates[0]);
      final lat = _asDouble(coordinates[1]);
      if (lat != null && lng != null) {
        return (latitude: lat, longitude: lng);
      }
    }

    return (latitude: latitude, longitude: longitude);
  }

  EventFriendResume _mapEventFriendResume(Map<String, dynamic> dto) {
    final displayName =
        (dto['display_name'] as String?) ?? (dto['name'] as String?) ?? '';
    final avatarUrlValue = UserAvatarValue();
    final normalizedAvatarUrl = (dto['avatar_url'] as String?)?.trim();
    if (normalizedAvatarUrl != null && normalizedAvatarUrl.isNotEmpty) {
      avatarUrlValue.parse(normalizedAvatarUrl);
    }

    return EventFriendResume(
      idValue: UserIdValue()..parse(dto['id'] as String? ?? ''),
      displayNameValue: UserDisplayNameValue()..parse(displayName),
      avatarUrlValue: avatarUrlValue,
    );
  }

  SentInviteStatus _mapSentInviteStatus(Map<String, dynamic> dto) {
    final friendMap = dto['friend'] as Map<String, dynamic>? ?? {};
    final sentAtValue = DateTimeValue()..parse(dto['sent_at'] as String);
    final respondedAtRaw = dto['responded_at'] as String?;
    final respondedAtValue = respondedAtRaw == null
        ? null
        : (DateTimeValue()..parse(respondedAtRaw));
    return SentInviteStatus(
      friend: _mapEventFriendResume(friendMap),
      status: _parseInviteStatus(dto['status'] as String?),
      sentAtValue: sentAtValue,
      respondedAtValue: respondedAtValue,
    );
  }

  InviteStatus _parseInviteStatus(String? rawStatus) {
    switch (rawStatus?.toLowerCase()) {
      case 'accepted':
        return InviteStatus.accepted;
      case 'declined':
        return InviteStatus.declined;
      case 'viewed':
        return InviteStatus.viewed;
      default:
        return InviteStatus.pending;
    }
  }

  PartnerResume _mapPartnerResume(Map<String, dynamic> dto) {
    SlugValue? slugValue;
    final slugRaw = dto['slug']?.toString();
    if (slugRaw != null && slugRaw.isNotEmpty) {
      slugValue = SlugValue()..parse(slugRaw);
    }

    InvitePartnerTaglineValue? taglineValue;
    final taglineRaw = dto['tagline']?.toString();
    if (taglineRaw != null && taglineRaw.isNotEmpty) {
      taglineValue = InvitePartnerTaglineValue()..parse(taglineRaw);
    }

    InvitePartnerLogoImageValue? logoImageValue;
    final logoUrl = dto['logo_url']?.toString();
    if (logoUrl != null && logoUrl.isNotEmpty) {
      logoImageValue = InvitePartnerLogoImageValue()..parse(logoUrl);
    }

    InvitePartnerHeroImageValue? heroImageValue;
    final heroUrl = dto['hero_image_url']?.toString();
    if (heroUrl != null && heroUrl.isNotEmpty) {
      heroImageValue = InvitePartnerHeroImageValue()..parse(heroUrl);
    }

    return PartnerResume(
      idValue: MongoIDValue()..parse(dto['id']?.toString() ?? ''),
      nameValue: InvitePartnerNameValue()
        ..parse(dto['display_name']?.toString() ?? ''),
      slugValue: slugValue,
      type: InviteAccountProfileType.mercadoProducer,
      taglineValue: taglineValue,
      logoImageValue: logoImageValue,
      heroImageValue: heroImageValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'type': {
        'id': type.id,
        'name': type.name,
        'slug': type.slug,
        'description': type.description,
        'icon': type.icon,
        'color': type.color,
      },
      'title': title,
      'content': content,
      'location': location,
      'venue': venue,
      'latitude': latitude,
      'longitude': longitude,
      'thumb': thumb != null
          ? {
              'type': thumb!.type,
              'data': thumb!.data,
            }
          : null,
      'date_time_start': dateTimeStart,
      'date_time_end': dateTimeEnd,
      'is_confirmed': isConfirmed,
      'total_confirmed': totalConfirmed,
      'received_invites': receivedInvites,
      'sent_invites': sentInvites,
      'friends_going': friendsGoing,
      'tags': tags,
    };
  }
}
