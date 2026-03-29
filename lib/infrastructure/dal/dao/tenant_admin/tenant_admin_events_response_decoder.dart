import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';

class TenantAdminEventsResponseDecoder {
  const TenantAdminEventsResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  List<TenantAdminEvent> decodeEventList(Object? rawResponse) {
    final rows = _envelopeDecoder.decodeListMap(
      rawResponse,
      label: 'events',
      allowRawList: true,
    );
    return rows.map(_mapEvent).toList(growable: false);
  }

  TenantAdminEvent decodeEventItem(Object? rawResponse) {
    final row = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'event',
    );
    return _mapEvent(row);
  }

  List<TenantAdminEventType> decodeEventTypeList(Object? rawResponse) {
    final rows = _envelopeDecoder.decodeListMap(
      rawResponse,
      label: 'event types',
      allowRawList: true,
    );
    return rows.map(_mapEventType).toList(growable: false);
  }

  TenantAdminEventType decodeEventTypeItem(Object? rawResponse) {
    final row = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'event type',
    );
    return _mapEventType(row);
  }

  TenantAdminEventPartyCandidates decodePartyCandidates(Object? rawResponse) {
    final envelope = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'event party candidates',
    );
    final physicalHosts = _decodeAccountProfiles(envelope['physical_hosts']);
    final artists = _decodeAccountProfiles(envelope['artists']);

    return TenantAdminEventPartyCandidates(
      venues: physicalHosts,
      artists: artists,
    );
  }

  String decodeErrorMessage({
    required Object? payload,
    required String fallback,
  }) {
    final map = _asMap(payload);
    final message = _asString(map['message']);
    if (message != null && message.isNotEmpty) {
      return message;
    }
    if (map.isNotEmpty) {
      return map.toString();
    }
    return fallback;
  }

  TenantAdminEvent _mapEvent(Map<String, dynamic> row) {
    final typeRow = _asMap(row['type']);
    final publicationRow = _asMap(row['publication']);
    final locationRow = _asMap(row['location']);
    final placeRefRow = _asMap(row['place_ref']);
    final thumbRow = _asMap(row['thumb']);
    final thumbData = _asMap(thumbRow['data']);
    final thumbUrl = _asString(thumbData['url']) ??
        _asString(thumbRow['url']) ??
        _asString(thumbRow['uri']);

    final occurrencesRaw = _asList(row['occurrences']);
    final occurrences = occurrencesRaw
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map((item) {
          final start = _parseDate(item['date_time_start']);
          if (start == null) {
            return null;
          }
          return TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText(
              _asString(item['occurrence_id']),
            ),
            occurrenceSlugValue: tenantAdminOptionalText(
              _asString(item['occurrence_slug']),
            ),
            dateTimeStartValue: tenantAdminDateTime(start),
            dateTimeEndValue: tenantAdminOptionalDateTime(
              _parseDate(item['date_time_end']),
            ),
          );
        })
        .whereType<TenantAdminEventOccurrence>()
        .toList(growable: false);

    final artistIdsRaw = _asList(row['artist_ids']);
    final artistIds = artistIdsRaw
        .map(_asString)
        .where((value) => value != null && value.isNotEmpty)
        .cast<String>()
        .toList(growable: false);

    final taxonomyTermsRaw = _asList(row['taxonomy_terms']);
    final taxonomyTerms = taxonomyTermsRaw
        .map(_asMap)
        .where((term) => term.isNotEmpty)
        .map((term) {
          final type = _asString(term['type']) ?? '';
          final value = _asString(term['value']) ?? '';
          return TenantAdminTaxonomyTerm(type: type, value: value);
        })
        .where((term) => term.type.isNotEmpty && term.value.isNotEmpty)
        .toList(
          growable: false,
        );

    final eventPartiesRaw = _asList(row['event_parties']);
    final eventParties = eventPartiesRaw
        .map(_asMap)
        .where((party) => party.isNotEmpty)
        .map((party) {
          final permissions = _asMap(party['permissions']);
          final canEdit = permissions['can_edit'] == true;
          return TenantAdminEventParty(
            partyTypeValue: tenantAdminRequiredText(
              _asString(party['party_type']) ?? '',
            ),
            partyRefIdValue: tenantAdminRequiredText(
              _asString(party['party_ref_id']) ?? '',
            ),
            canEditValue: tenantAdminFlag(canEdit),
            metadataValue: tenantAdminDynamicMap(_asMap(party['metadata'])),
          );
        })
        .where((party) =>
            party.partyType.isNotEmpty && party.partyRefId.isNotEmpty)
        .toList(
          growable: false,
        );

    final onlineRow = _asMap(locationRow['online']);
    final mode = _asString(locationRow['mode']) ?? '';
    final latitude = _toDouble(row['latitude']);
    final longitude = _toDouble(row['longitude']);

    final location = mode.isEmpty
        ? null
        : TenantAdminEventLocation(
            mode: mode,
            latitude: latitude,
            longitude: longitude,
            online: onlineRow.isEmpty
                ? null
                : TenantAdminEventOnlineLocation(
                    url: _asString(onlineRow['url']) ?? '',
                    platform: _asString(onlineRow['platform']),
                    label: _asString(onlineRow['label']),
                  ),
          );

    final placeRef = placeRefRow.isEmpty
        ? null
        : TenantAdminEventPlaceRef(
            typeValue: tenantAdminRequiredText(
              _asString(placeRefRow['type']) ?? '',
            ),
            idValue: tenantAdminRequiredText(
              _asString(placeRefRow['id']) ?? '',
            ),
            metadataValue:
                tenantAdminDynamicMap(_asMap(placeRefRow['metadata'])),
          );

    final dateTimeStart = _parseDate(row['date_time_start']);
    if (occurrences.isEmpty && dateTimeStart != null) {
      final fallbackOccurrence = TenantAdminEventOccurrence(
        dateTimeStartValue: tenantAdminDateTime(dateTimeStart),
        dateTimeEndValue: tenantAdminOptionalDateTime(
          _parseDate(row['date_time_end']),
        ),
      );
      return TenantAdminEvent(
        eventId: _asString(row['event_id']) ?? _asString(row['id']) ?? '',
        slug: _asString(row['slug']) ?? '',
        title: _asString(row['title']) ?? '',
        content: _asString(row['content']) ?? '',
        type: TenantAdminEventType(
          id: _asString(typeRow['id']),
          name: _asString(typeRow['name']) ?? '',
          slug: _asString(typeRow['slug']) ?? '',
          description: _asString(typeRow['description']),
          icon: _asString(typeRow['icon']),
          color: _asString(typeRow['color']),
        ),
        location: location,
        placeRef: placeRef,
        thumbUrl: thumbUrl,
        occurrences: <TenantAdminEventOccurrence>[fallbackOccurrence],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText(
              _asString(publicationRow['status']) ?? 'draft'),
          publishAtValue: tenantAdminOptionalDateTime(
            _parseDate(publicationRow['publish_at']),
          ),
        ),
        artistIds: artistIds,
        eventParties: eventParties,
        taxonomyTerms: taxonomyTerms,
        createdAt: _parseDate(row['created_at']),
        updatedAt: _parseDate(row['updated_at']),
        deletedAt: _parseDate(row['deleted_at']),
      );
    }

    return TenantAdminEvent(
      eventId: _asString(row['event_id']) ?? _asString(row['id']) ?? '',
      slug: _asString(row['slug']) ?? '',
      title: _asString(row['title']) ?? '',
      content: _asString(row['content']) ?? '',
      type: TenantAdminEventType(
        id: _asString(typeRow['id']),
        name: _asString(typeRow['name']) ?? '',
        slug: _asString(typeRow['slug']) ?? '',
        description: _asString(typeRow['description']),
        icon: _asString(typeRow['icon']),
        color: _asString(typeRow['color']),
      ),
      location: location,
      placeRef: placeRef,
      thumbUrl: thumbUrl,
      occurrences: occurrences,
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText(
            _asString(publicationRow['status']) ?? 'draft'),
        publishAtValue: tenantAdminOptionalDateTime(
          _parseDate(publicationRow['publish_at']),
        ),
      ),
      artistIds: artistIds,
      eventParties: eventParties,
      taxonomyTerms: taxonomyTerms,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
      deletedAt: _parseDate(row['deleted_at']),
    );
  }

  TenantAdminEventType _mapEventType(Map<String, dynamic> row) {
    return TenantAdminEventType(
      id: _asString(row['id']),
      name: _asString(row['name']) ?? '',
      slug: _asString(row['slug']) ?? '',
      description: _asString(row['description']),
      icon: _asString(row['icon']),
      color: _asString(row['color']),
    );
  }

  TenantAdminAccountProfile _mapAccountProfile(Map<String, dynamic> row) {
    final locationRow = _asMap(row['location']);
    final lat = _toDouble(locationRow['lat']);
    final lng = _toDouble(locationRow['lng']);

    final taxonomyTerms = _asList(row['taxonomy_terms'])
        .map(_asMap)
        .where((term) => term.isNotEmpty)
        .map((term) => TenantAdminTaxonomyTerm(
              type: _asString(term['type']) ?? '',
              value: _asString(term['value']) ?? '',
            ))
        .where((term) => term.type.isNotEmpty && term.value.isNotEmpty)
        .toList(growable: false);

    return TenantAdminAccountProfile(
      id: _asString(row['id']) ?? '',
      accountId: _asString(row['account_id']) ?? '',
      profileType: _asString(row['profile_type']) ?? '',
      displayName: _asString(row['display_name']) ?? '',
      slug: _asString(row['slug']),
      avatarUrl: _asString(row['avatar_url']),
      coverUrl: _asString(row['cover_url']),
      bio: _asString(row['bio']),
      content: _asString(row['content']),
      location: lat != null && lng != null
          ? TenantAdminLocation(latitude: lat, longitude: lng)
          : null,
      taxonomyTerms: taxonomyTerms,
    );
  }

  List<TenantAdminAccountProfile> _decodeAccountProfiles(Object? raw) {
    return _asList(raw)
        .whereType<Map>()
        .map((row) => _mapAccountProfile(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  List<Object?> _asList(Object? value) {
    if (value is List) {
      return value;
    }
    return const <Object?>[];
  }

  String? _asString(Object? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.toString();
    if (normalized.trim().isEmpty) {
      return null;
    }
    return normalized;
  }

  double? _toDouble(Object? value) {
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

  DateTime? _parseDate(Object? value) {
    if (value is DateTime) {
      return TimezoneConverter.utcToLocal(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        return null;
      }
      return TimezoneConverter.utcToLocal(parsed);
    }
    return null;
  }
}
