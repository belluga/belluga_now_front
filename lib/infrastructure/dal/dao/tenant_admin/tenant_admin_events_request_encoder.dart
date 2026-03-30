import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';

class TenantAdminEventsRequestEncoder {
  const TenantAdminEventsRequestEncoder();

  Map<String, dynamic> encodeEventTypePatch({
    String? name,
    String? slug,
    String? description,
    bool includeDescription = false,
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
    return payload;
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
          .map((occurrence) => <String, dynamic>{
                'date_time_start':
                    occurrence.dateTimeStart.toUtc().toIso8601String(),
                if (occurrence.dateTimeEnd != null)
                  'date_time_end':
                      occurrence.dateTimeEnd!.toUtc().toIso8601String(),
              })
          .toList(growable: false),
      'publication': <String, dynamic>{
        'status': draft.publication.status,
        if (draft.publication.publishAt != null)
          'publish_at': draft.publication.publishAt!.toUtc().toIso8601String(),
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

    if (draft.artistIds.isNotEmpty) {
      payload['artist_ids'] = draft.artistIds
          .map((artistId) => artistId.value)
          .toList(growable: false);
    }

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
      payload['location'] = locationPayload;
    }

    if (draft.placeRef != null) {
      payload['place_ref'] = <String, dynamic>{
        'type': draft.placeRef!.type,
        'id': draft.placeRef!.id,
        if (draft.placeRef!.metadata != null &&
            draft.placeRef!.metadata!.isNotEmpty)
          'metadata': draft.placeRef!.metadata,
      };
    } else if (location != null && location.mode == 'online') {
      payload['place_ref'] = null;
    }

    return payload;
  }
}
