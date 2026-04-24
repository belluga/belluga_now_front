import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';

class TenantAdminEventsRequestEncoder {
  const TenantAdminEventsRequestEncoder();

  Map<String, dynamic> encodeEventTypePatch({
    String? name,
    String? slug,
    String? description,
    List<String>? allowedTaxonomies,
    TenantAdminPoiVisual? visual,
    bool includeDescription = false,
    bool includeVisual = false,
    bool removeTypeAsset = false,
  }) {
    final payload = <String, dynamic>{};
    if (name != null) {
      payload['name'] = name;
    }
    if (slug != null) {
      payload['slug'] = slug;
    }
    if (includeDescription || description != null) {
      payload['description'] = description;
    }
    if (allowedTaxonomies != null) {
      payload['allowed_taxonomies'] = List<String>.from(allowedTaxonomies);
    }
    if (includeVisual) {
      payload['visual'] = visual?.toJson();
      payload['poi_visual'] = visual?.toJson();
    }
    if (removeTypeAsset) {
      payload['remove_type_asset'] = true;
    }
    return payload;
  }

  Map<String, dynamic> encodeEventTypeCreate({
    required String name,
    required String slug,
    String? description,
    List<String>? allowedTaxonomies,
    TenantAdminPoiVisual? visual,
    bool includeVisual = false,
  }) {
    return {
      'name': name,
      'slug': slug,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (allowedTaxonomies != null)
        'allowed_taxonomies': List<String>.from(allowedTaxonomies),
      if (includeVisual) 'visual': visual?.toJson(),
      if (includeVisual) 'poi_visual': visual?.toJson(),
    };
  }

  Map<String, dynamic> encodeDraft(TenantAdminEventDraft draft) {
    final payload = <String, dynamic>{
      'title': draft.title,
      'content': draft.content,
      'type': <String, dynamic>{
        'name': draft.type.name,
        'slug': draft.type.slug,
        if (draft.type.id != null && draft.type.id!.trim().isNotEmpty)
          'id': draft.type.id,
        if (draft.type.description != null)
          'description': draft.type.description,
        if (draft.type.icon != null) 'icon': draft.type.icon,
        if (draft.type.color != null) 'color': draft.type.color,
      },
      'occurrences': draft.occurrences
          .map((occurrence) => _encodeOccurrence(occurrence))
          .toList(growable: false),
      'publication': <String, dynamic>{
        'status': draft.publication.status,
        if (draft.publication.publishAt != null)
          'publish_at': TimezoneConverter.localToUtc(
            draft.publication.publishAt!,
          ).toIso8601String(),
      },
    };

    if (draft.taxonomyTerms.isNotEmpty) {
      payload['taxonomy_terms'] = draft.taxonomyTerms
          .map((term) => <String, dynamic>{
                'type': term.type,
                'value': term.value,
              })
          .toList(growable: false);
    }

    payload['event_parties'] = draft.relatedAccountProfileIds.map((profileId) {
      return <String, dynamic>{
        'party_ref_id': profileId.value,
        'permissions': <String, dynamic>{
          'can_edit': true,
        },
      };
    }).toList(growable: false);

    final normalizedCoverUrl = draft.coverUrl?.trim();
    if (normalizedCoverUrl != null && normalizedCoverUrl.isNotEmpty) {
      payload['thumb'] = <String, dynamic>{
        'type': 'image',
        'data': <String, dynamic>{
          'url': normalizedCoverUrl,
        },
      };
    }

    final location = draft.location;
    if (location != null) {
      payload['location'] = _encodeLocation(location);
    }

    if (draft.placeRef != null) {
      payload['place_ref'] = <String, dynamic>{
        'type': draft.placeRef!.type,
        'id': draft.placeRef!.id,
      };
    } else if (location != null && location.mode == 'online') {
      payload['place_ref'] = null;
    }

    return payload;
  }

  Map<String, dynamic> _encodeOccurrence(
    TenantAdminEventOccurrence occurrence,
  ) {
    final payload = <String, dynamic>{
      'date_time_start': TimezoneConverter.localToUtc(
        occurrence.dateTimeStart,
      ).toIso8601String(),
      if (occurrence.dateTimeEnd != null)
        'date_time_end': TimezoneConverter.localToUtc(
          occurrence.dateTimeEnd!,
        ).toIso8601String(),
    };

    if (occurrence.relatedAccountProfileIds.isNotEmpty) {
      payload['event_parties'] =
          occurrence.relatedAccountProfileIds.map((profileId) {
        return <String, dynamic>{
          'party_ref_id': profileId.value,
          'permissions': <String, dynamic>{
            'can_edit': true,
          },
        };
      }).toList(growable: false);
    }

    if (occurrence.programmingItems.isNotEmpty) {
      payload['programming_items'] = occurrence.programmingItems
          .map(
            (item) => <String, dynamic>{
              'time': item.time,
              if (item.title != null) 'title': item.title,
              if (item.accountProfileIds.isNotEmpty)
                'account_profile_ids': item.accountProfileIds
                    .map((profileId) => profileId.value)
                    .toList(growable: false),
              if (item.placeRef != null)
                'place_ref': <String, dynamic>{
                  'type': item.placeRef!.type,
                  'id': item.placeRef!.id,
                },
            },
          )
          .toList(growable: false);
    }

    return payload;
  }

  Map<String, dynamic> _encodeLocation(TenantAdminEventLocation location) {
    final locationPayload = <String, dynamic>{
      'mode': location.mode,
    };
    final includesPhysicalGeometry =
        location.mode == 'physical' || location.mode == 'hybrid';
    if (includesPhysicalGeometry &&
        location.latitude != null &&
        location.longitude != null) {
      locationPayload['geo'] = <String, dynamic>{
        'type': 'Point',
        'coordinates': <double>[location.longitude!, location.latitude!],
      };
    }
    if (location.online != null) {
      locationPayload['online'] = <String, dynamic>{
        'url': location.online!.url,
        if (location.online!.platform != null)
          'platform': location.online!.platform,
        if (location.online!.label != null) 'label': location.online!.label,
      };
    }
    return locationPayload;
  }
}
