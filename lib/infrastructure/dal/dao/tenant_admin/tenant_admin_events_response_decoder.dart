import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
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

  List<TenantAdminAccountProfile> decodeAccountProfileCandidates(
    Object? rawResponse,
  ) {
    final envelope = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'event account profile candidates',
    );
    return _decodeAccountProfiles(envelope['data']);
  }

  TenantAdminLegacyEventPartiesSummary decodeLegacyEventPartiesSummary(
    Object? rawResponse,
  ) {
    final row = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'legacy event parties summary',
    );
    final data = _asMap(row['data']);
    final summary = data.isEmpty ? row : data;

    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: tenantAdminCount(summary['scanned']),
      invalidValue: tenantAdminCount(summary['invalid']),
      repairedValue: tenantAdminCount(summary['repaired']),
      unchangedValue: tenantAdminCount(summary['unchanged']),
      failedValue: tenantAdminCount(summary['failed']),
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
    final venueRow = _asMap(row['venue']);
    final thumbRow = _asMap(row['thumb']);
    final thumbData = _asMap(thumbRow['data']);
    final thumbUrl = _asString(thumbData['url']) ??
        _asString(thumbRow['url']) ??
        _asString(thumbRow['uri']);
    final venueDisplayName =
        _asString(venueRow['display_name']) ?? _asString(venueRow['name']);

    final occurrencesRaw = _asList(row['occurrences']);
    final occurrences = occurrencesRaw
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map(_mapOccurrence)
        .whereType<TenantAdminEventOccurrence>()
        .toList(growable: false);

    final eventPartiesRaw = _asList(row['event_parties']);
    final relatedAccountProfileIds = eventPartiesRaw
        .map(_asMap)
        .where((party) => (_asString(party['party_type']) ?? '') != 'venue')
        .map((party) => party['party_ref_id'])
        .map(_asString)
        .where((value) => value != null && value.isNotEmpty)
        .cast<String>()
        .map(TenantAdminAccountProfileIdValue.new)
        .toList(growable: false);
    final relatedAccountProfiles = _decodeRelatedAccountProfiles(
      row['linked_account_profiles'],
    );

    final taxonomyTermsRaw = _asList(row['taxonomy_terms']);
    final taxonomyTerms = taxonomyTermsRaw
        .map(_asMap)
        .where((term) => term.isNotEmpty)
        .map(_mapTaxonomyTerm)
        .where((term) => term.type.isNotEmpty && term.value.isNotEmpty)
        .toList(
          growable: false,
        );

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
            modeValue: tenantAdminRequiredText(mode),
            latitudeValue: tenantAdminOptionalDouble(latitude),
            longitudeValue: tenantAdminOptionalDouble(longitude),
            online: onlineRow.isEmpty
                ? null
                : TenantAdminEventOnlineLocation(
                    urlValue: tenantAdminRequiredText(
                      _asString(onlineRow['url']) ?? '',
                    ),
                    platformValue: tenantAdminOptionalText(
                      _asString(onlineRow['platform']),
                    ),
                    labelValue: tenantAdminOptionalText(
                      _asString(onlineRow['label']),
                    ),
                  ),
          );

    final placeRef = placeRefRow.isEmpty
        ? null
        : TenantAdminEventPlaceRef(
            typeValue: tenantAdminRequiredText(
              _asString(placeRefRow['type']) ?? '',
            ),
            idValue: tenantAdminRequiredText(
              _extractPlaceRefId(placeRefRow) ?? '',
            ),
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
        eventIdValue: tenantAdminRequiredText(
            _asString(row['event_id']) ?? _asString(row['id']) ?? ''),
        slugValue: tenantAdminRequiredText(_asString(row['slug']) ?? ''),
        titleValue: tenantAdminRequiredText(_asString(row['title']) ?? ''),
        contentValue: tenantAdminOptionalText(_asString(row['content']) ?? ''),
        type: TenantAdminEventType(
          idValue: tenantAdminOptionalText(_asString(typeRow['id'])),
          nameValue: tenantAdminRequiredText(_asString(typeRow['name']) ?? ''),
          slugValue: tenantAdminRequiredText(_asString(typeRow['slug']) ?? ''),
          descriptionValue: tenantAdminOptionalText(
            _asString(typeRow['description']),
          ),
          iconValue: tenantAdminOptionalText(_asString(typeRow['icon'])),
          colorValue: tenantAdminOptionalText(_asString(typeRow['color'])),
          visual: _decodeEventTypeVisual(typeRow),
        ),
        location: location,
        placeRef: placeRef,
        thumbUrlValue: tenantAdminOptionalUrl(thumbUrl),
        venueDisplayNameValue: tenantAdminOptionalText(venueDisplayName),
        occurrences: <TenantAdminEventOccurrence>[fallbackOccurrence],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText(
              _asString(publicationRow['status']) ?? 'draft'),
          publishAtValue: tenantAdminOptionalDateTime(
            _parseDate(publicationRow['publish_at']),
          ),
        ),
        relatedAccountProfileIdValues: relatedAccountProfileIds,
        relatedAccountProfiles: relatedAccountProfiles,
        eventParties: eventParties,
        taxonomyTerms: (() {
          final terms = TenantAdminTaxonomyTerms();
          for (final taxonomyTerm in taxonomyTerms) {
            terms.add(taxonomyTerm);
          }
          return terms;
        })(),
        createdAtValue:
            tenantAdminOptionalDateTime(_parseDate(row['created_at'])),
        updatedAtValue:
            tenantAdminOptionalDateTime(_parseDate(row['updated_at'])),
        deletedAtValue:
            tenantAdminOptionalDateTime(_parseDate(row['deleted_at'])),
      );
    }

    return TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText(
          _asString(row['event_id']) ?? _asString(row['id']) ?? ''),
      slugValue: tenantAdminRequiredText(_asString(row['slug']) ?? ''),
      titleValue: tenantAdminRequiredText(_asString(row['title']) ?? ''),
      contentValue: tenantAdminOptionalText(_asString(row['content']) ?? ''),
      type: TenantAdminEventType(
        idValue: tenantAdminOptionalText(_asString(typeRow['id'])),
        nameValue: tenantAdminRequiredText(_asString(typeRow['name']) ?? ''),
        slugValue: tenantAdminRequiredText(_asString(typeRow['slug']) ?? ''),
        descriptionValue:
            tenantAdminOptionalText(_asString(typeRow['description'])),
        iconValue: tenantAdminOptionalText(_asString(typeRow['icon'])),
        colorValue: tenantAdminOptionalText(_asString(typeRow['color'])),
        visual: _decodeEventTypeVisual(typeRow),
      ),
      location: location,
      placeRef: placeRef,
      thumbUrlValue: tenantAdminOptionalUrl(thumbUrl),
      venueDisplayNameValue: tenantAdminOptionalText(venueDisplayName),
      occurrences: occurrences,
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText(
            _asString(publicationRow['status']) ?? 'draft'),
        publishAtValue: tenantAdminOptionalDateTime(
          _parseDate(publicationRow['publish_at']),
        ),
      ),
      relatedAccountProfileIdValues: relatedAccountProfileIds,
      relatedAccountProfiles: relatedAccountProfiles,
      eventParties: eventParties,
      taxonomyTerms: (() {
        final terms = TenantAdminTaxonomyTerms();
        for (final taxonomyTerm in taxonomyTerms) {
          terms.add(taxonomyTerm);
        }
        return terms;
      })(),
      createdAtValue:
          tenantAdminOptionalDateTime(_parseDate(row['created_at'])),
      updatedAtValue:
          tenantAdminOptionalDateTime(_parseDate(row['updated_at'])),
      deletedAtValue:
          tenantAdminOptionalDateTime(_parseDate(row['deleted_at'])),
    );
  }

  TenantAdminEventType _mapEventType(Map<String, dynamic> row) {
    return TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText(_asString(row['id'])),
      nameValue: tenantAdminRequiredText(_asString(row['name']) ?? ''),
      slugValue: tenantAdminRequiredText(_asString(row['slug']) ?? ''),
      descriptionValue: tenantAdminOptionalText(_asString(row['description'])),
      iconValue: tenantAdminOptionalText(_asString(row['icon'])),
      colorValue: tenantAdminOptionalText(_asString(row['color'])),
      allowedTaxonomiesValue: tenantAdminTrimmedStringList(
        row['allowed_taxonomies'],
      ),
      visual: _decodeEventTypeVisual(row),
    );
  }

  TenantAdminEventOccurrence? _mapOccurrence(Map<String, dynamic> item) {
    final start = _parseDate(item['date_time_start']);
    if (start == null) {
      return null;
    }
    final ownProfiles = _decodeRelatedAccountProfiles(
      item['own_linked_account_profiles'] ?? item['linked_account_profiles'],
    );
    final ownParties =
        _asList(item['own_event_parties'] ?? item['event_parties'])
            .map(_asMap)
            .where((party) => party.isNotEmpty)
            .toList(growable: false);
    final ownProfileIds = ownParties.isNotEmpty
        ? _mapPartyProfileIds(ownParties)
        : ownProfiles
            .where((profile) => profile.profileType.trim() != 'venue')
            .map((profile) => TenantAdminAccountProfileIdValue(profile.id))
            .toList(growable: false);

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
      relatedAccountProfileIdValues: ownProfileIds,
      relatedAccountProfiles: ownProfiles,
      programmingItems: _mapProgrammingItems(item['programming_items']),
    );
  }

  List<TenantAdminAccountProfileIdValue> _mapPartyProfileIds(
    List<Map<String, dynamic>> parties,
  ) {
    return parties
        .where((party) => (_asString(party['party_type']) ?? '') != 'venue')
        .map((party) => _asString(party['party_ref_id']))
        .where((value) => value != null && value.isNotEmpty)
        .cast<String>()
        .map(TenantAdminAccountProfileIdValue.new)
        .toList(growable: false);
  }

  List<TenantAdminEventProgrammingItem> _mapProgrammingItems(Object? raw) {
    return _asList(raw)
        .map(_asMap)
        .where((item) => item.isNotEmpty)
        .map((item) {
          final linkedProfiles = _decodeRelatedAccountProfiles(
            item['linked_account_profiles'],
          );
          final profileIds = _asList(item['account_profile_ids']).isNotEmpty
              ? _asList(item['account_profile_ids'])
                  .map(_asString)
                  .where((value) => value != null && value.isNotEmpty)
                  .cast<String>()
                  .map(TenantAdminAccountProfileIdValue.new)
                  .toList(growable: false)
              : linkedProfiles
                  .map(
                      (profile) => TenantAdminAccountProfileIdValue(profile.id))
                  .toList(growable: false);
          return TenantAdminEventProgrammingItem(
            timeValue: tenantAdminRequiredText(_asString(item['time']) ?? ''),
            titleValue: tenantAdminOptionalText(_asString(item['title'])),
            accountProfileIdValues: profileIds,
            linkedAccountProfiles: linkedProfiles,
            placeRef: _mapProgrammingPlaceRef(item['place_ref']),
          );
        })
        .where((item) => item.time.isNotEmpty)
        .toList(growable: false);
  }

  TenantAdminEventPlaceRef? _mapProgrammingPlaceRef(Object? raw) {
    final row = _asMap(raw);
    if (row.isEmpty) {
      return null;
    }
    final type = _asString(row['type']) ?? '';
    final id = _extractPlaceRefId(row) ?? '';
    if (type.isEmpty || id.isEmpty) {
      return null;
    }
    return TenantAdminEventPlaceRef(
      typeValue: tenantAdminRequiredText(type),
      idValue: tenantAdminRequiredText(id),
    );
  }

  TenantAdminPoiVisual? _decodeEventTypeVisual(Map<String, dynamic> row) {
    final visualRow = _asMap(row['visual']);
    final fallbackVisualRow =
        visualRow.isNotEmpty ? visualRow : _asMap(row['poi_visual']);
    if (fallbackVisualRow.isEmpty) {
      final icon = _asString(row['icon']);
      final color = _asString(row['color']);
      if (icon == null || icon.isEmpty || color == null || color.isEmpty) {
        return null;
      }
      try {
        final iconValue = TenantAdminRequiredTextValue()..parse(icon);
        final colorValue = TenantAdminHexColorValue()..parse(color);
        final iconColorValue = TenantAdminHexColorValue()
          ..parse(_asString(row['icon_color']) ?? '#FFFFFF');
        return TenantAdminPoiVisual.icon(
          iconValue: iconValue,
          colorValue: colorValue,
          iconColorValue: iconColorValue,
        );
      } on Object {
        return null;
      }
    }

    final mode = (_asString(fallbackVisualRow['mode']) ?? '').trim();
    if (mode == TenantAdminPoiVisualMode.icon.apiValue) {
      try {
        final iconValue = TenantAdminRequiredTextValue()
          ..parse(_asString(fallbackVisualRow['icon']) ?? '');
        final colorValue = TenantAdminHexColorValue()
          ..parse(_asString(fallbackVisualRow['color']) ?? '');
        final iconColorValue = TenantAdminHexColorValue()
          ..parse(_asString(fallbackVisualRow['icon_color']) ?? '#FFFFFF');
        return TenantAdminPoiVisual.icon(
          iconValue: iconValue,
          colorValue: colorValue,
          iconColorValue: iconColorValue,
        );
      } on Object {
        return null;
      }
    }

    if (mode != TenantAdminPoiVisualMode.image.apiValue) {
      return null;
    }

    final imageSourceRaw =
        (_asString(fallbackVisualRow['image_source']) ?? '').trim();
    TenantAdminPoiVisualImageSource? imageSource;
    for (final candidate in TenantAdminPoiVisualImageSource.values) {
      if (candidate.apiValue == imageSourceRaw) {
        imageSource = candidate;
        break;
      }
    }
    if (imageSource == null) {
      return null;
    }

    return TenantAdminPoiVisual.image(
      imageSource: imageSource,
      imageUrlValue:
          tenantAdminOptionalUrl(_asString(fallbackVisualRow['image_url'])),
    );
  }

  TenantAdminAccountProfile _mapAccountProfile(Map<String, dynamic> row) {
    final locationRow = _asMap(row['location']);
    final lat = _toDouble(locationRow['lat']);
    final lng = _toDouble(locationRow['lng']);

    final taxonomyTerms = _asList(row['taxonomy_terms'])
        .map(_asMap)
        .where((term) => term.isNotEmpty)
        .map(_mapTaxonomyTerm)
        .where((term) => term.type.isNotEmpty && term.value.isNotEmpty)
        .toList(growable: false);

    return tenantAdminAccountProfileFromRaw(
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
          ? tenantAdminLocationFromRaw(latitude: lat, longitude: lng)
          : null,
      taxonomyTerms: (() {
        final terms = TenantAdminTaxonomyTerms();
        for (final taxonomyTerm in taxonomyTerms) {
          terms.add(taxonomyTerm);
        }
        return terms;
      })(),
    );
  }

  TenantAdminAccountProfile _mapRelatedAccountProfile(
    Map<String, dynamic> row,
  ) {
    final taxonomyTerms = _asList(row['taxonomy_terms'])
        .map(_asMap)
        .where((term) => term.isNotEmpty)
        .map(_mapTaxonomyTerm)
        .where((term) => term.type.isNotEmpty && term.value.isNotEmpty)
        .toList(growable: false);

    final id = _asString(row['id']) ?? '';

    return tenantAdminAccountProfileFromRaw(
      id: id,
      accountId:
          _asString(row['account_id']) ?? _asString(row['accountId']) ?? id,
      profileType: _asString(row['profile_type']) ??
          _asString(row['profileType']) ??
          _asString(row['party_type']) ??
          '',
      displayName:
          _asString(row['display_name']) ?? _asString(row['name']) ?? '',
      slug: _asString(row['slug']),
      avatarUrl: _asString(row['avatar_url']),
      coverUrl: _asString(row['cover_url']),
      bio: _asString(row['bio']),
      content: _asString(row['content']),
      taxonomyTerms: (() {
        final terms = TenantAdminTaxonomyTerms();
        for (final taxonomyTerm in taxonomyTerms) {
          terms.add(taxonomyTerm);
        }
        return terms;
      })(),
    );
  }

  List<TenantAdminAccountProfile> _decodeAccountProfiles(Object? raw) {
    return _asList(raw)
        .whereType<Map>()
        .map((row) => _mapAccountProfile(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  List<TenantAdminAccountProfile> _decodeRelatedAccountProfiles(Object? raw) {
    return _asList(raw)
        .whereType<Map>()
        .map((row) => _mapRelatedAccountProfile(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  TenantAdminTaxonomyTerm _mapTaxonomyTerm(Map<String, dynamic> term) {
    return tenantAdminTaxonomyTermFromRaw(
      type: _asString(term['type']) ?? '',
      value: _asString(term['value']) ?? '',
      name: _asString(term['name']),
      taxonomyName: _asString(term['taxonomy_name']),
      label: _asString(term['label']),
    );
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

    if (value is! String && value is! num && value is! bool) {
      throw FormatException('Invalid scalar text value: $value');
    }

    final normalized = value.toString();
    if (normalized.trim().isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _extractPlaceRefId(Map<String, dynamic> placeRefRow) {
    final direct = _asString(placeRefRow['id']);
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final legacy = placeRefRow['_id'];
    if (legacy is Map) {
      final oid = _asString(legacy[r'$oid'] ?? legacy['oid']);
      if (oid != null && oid.isNotEmpty) {
        return oid;
      }
    }

    return _asString(legacy);
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
    if (value is Map) {
      final wrapped = value[r'$date'] ?? value['date'];
      if (wrapped != null && wrapped != value) {
        return _parseDate(wrapped);
      }
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
