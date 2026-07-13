import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_gallery_group.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/projections/value_objects/partner_projection_text_values.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_member_text_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_taxonomy_filter.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/domain/shared/account_profile_contact_source_summary.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_channel_id_value.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_source_account_profile_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/services/location_origin_resolution_request_factory.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class LaravelAccountProfilesBackend implements AccountProfilesBackendContract {
  static const int _publicVisibleNameMinLength = 3;
  static const String _publicUnavailableProfileLabel = 'Perfil indisponível';

  LaravelAccountProfilesBackend({
    Dio? dio,
    LocationOriginServiceContract? locationOriginService,
  }) : this._internal(dio ?? Dio(), locationOriginService);

  LaravelAccountProfilesBackend._internal(
    this._dio, [
    this._locationOriginService,
  ]);

  final Dio _dio;
  LocationOriginServiceContract? _locationOriginService;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  LocationOriginServiceContract? get _resolvedLocationOriginService {
    if (_locationOriginService != null) {
      return _locationOriginService;
    }
    if (!GetIt.I.isRegistered<LocationOriginServiceContract>()) {
      return null;
    }
    _locationOriginService = GetIt.I.get<LocationOriginServiceContract>();
    return _locationOriginService;
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
    List<String>? allowedTypes,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': pageSize,
      };
      final trimmedQuery = query?.trim();
      if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
        queryParameters['search'] = trimmedQuery;
      }
      final normalizedTypes = _normalizeTypeFilters(
        typeFilter: typeFilter,
        typeFilters: typeFilters,
      );
      if (normalizedTypes.isNotEmpty) {
        final queryValue = normalizedTypes.length == 1
            ? normalizedTypes.single
            : normalizedTypes;
        queryParameters['profile_type'] = queryValue;
        queryParameters['filter'] = <String, dynamic>{
          'profile_type': queryValue,
        };
      }
      _appendTaxonomyQueryParameters(queryParameters, taxonomyFilters);

      final response =
          await TenantPublicAuthHeaders.retryOnceOnUnauthorized<Response>(
            includeJsonAccept: true,
            action: (headers) => _dio.get(
              '$_apiBaseUrl/v1/account_profiles',
              queryParameters: queryParameters,
              options: Options(headers: headers),
            ),
          );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profiles response shape.');
      }
      final data = _extractDataList(raw);

      final currentPage = _parsePageValue(raw['current_page']) ?? page;
      final hasMoreFlag = _asBool(raw['has_more']);
      final lastPage = _parsePageValue(raw['last_page']);
      final hasMore = raw.containsKey('has_more')
          ? hasMoreFlag
          : lastPage != null
          ? currentPage < lastPage
          : raw['next_page_url'] != null;

      final distanceOrigin = await _resolveDistanceOrigin();
      return pagedAccountProfilesResultFromRaw(
        profiles: _parseProfiles(data, distanceOrigin: distanceOrigin),
        hasMore: hasMore,
        discoveryFilterFacets: _parseDiscoveryFilterFacets(
          raw['discovery_filter_facets'],
        ),
        discoveryFilterCatalog: _parseDiscoveryFilterCatalog(
          raw['discovery_filter_catalog'],
        ),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load account profiles '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) async {
    final origin = await _resolveEffectiveOriginCoordinate();
    if (origin == null) {
      return const <AccountProfileModel>[];
    }

    final safePageSize = pageSize <= 0 ? 10 : pageSize.clamp(1, 50);
    try {
      final response =
          await TenantPublicAuthHeaders.retryOnceOnUnauthorized<Response>(
            includeJsonAccept: true,
            action: (headers) => _dio.get(
              '$_apiBaseUrl/v1/account_profiles/near',
              queryParameters: _nearQueryParameters(
                originLat: origin.latitude,
                originLng: origin.longitude,
                page: 1,
                pageSize: safePageSize,
                typeFilters: typeFilters,
                taxonomyFilters: taxonomyFilters,
              ),
              options: Options(headers: headers),
            ),
          );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profiles near response shape.');
      }

      final data = _extractDataList(raw);
      return _parseProfiles(data, distanceOrigin: origin);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load nearby account profiles '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  Map<String, dynamic> _nearQueryParameters({
    required double originLat,
    required double originLng,
    required int page,
    required int pageSize,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) {
    final queryParameters = <String, dynamic>{
      'origin_lat': originLat,
      'origin_lng': originLng,
      'page': page,
      'page_size': pageSize,
    };
    final normalizedTypes = _normalizeTypeFilters(typeFilters: typeFilters);
    if (normalizedTypes.isNotEmpty) {
      queryParameters['profile_type'] = normalizedTypes.length == 1
          ? normalizedTypes.single
          : normalizedTypes;
    }
    _appendTaxonomyQueryParameters(queryParameters, taxonomyFilters);

    return queryParameters;
  }

  List<String> _normalizeTypeFilters({
    String? typeFilter,
    List<String>? typeFilters,
  }) {
    return <String>{
      if (typeFilter != null && typeFilter.trim().isNotEmpty) typeFilter.trim(),
      for (final filter in typeFilters ?? const <String>[])
        if (filter.trim().isNotEmpty) filter.trim(),
    }.toList(growable: false);
  }

  void _appendTaxonomyQueryParameters(
    Map<String, dynamic> queryParameters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  ) {
    final normalized = <AccountProfilesRepositoryTaxonomyFilter>[];
    final seen = <String>{};
    for (final filter in taxonomyFilters ?? const []) {
      if (!filter.isValid) {
        continue;
      }
      final key = '${filter.type.value}:${filter.term.value}';
      if (seen.add(key)) {
        normalized.add(filter);
      }
    }

    for (var index = 0; index < normalized.length; index += 1) {
      final filter = normalized[index];
      queryParameters['taxonomy[$index][type]'] = filter.type.value;
      queryParameters['taxonomy[$index][value]'] = filter.term.value;
    }
  }

  DiscoveryFilterRuntimeFacets? _parseDiscoveryFilterFacets(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    return DiscoveryFilterRuntimeFacets.fromJson(
      raw.map((key, value) => MapEntry<String, Object?>(key.toString(), value)),
    );
  }

  DiscoveryFilterCatalog? _parseDiscoveryFilterCatalog(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    return DiscoveryFilterCatalog.fromJson(
      raw.map((key, value) => MapEntry<String, Object?>(key.toString(), value)),
    );
  }

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async {
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isEmpty) {
      return null;
    }

    try {
      final response =
          await TenantPublicAuthHeaders.retryOnceOnUnauthorized<Response>(
            includeJsonAccept: true,
            action: (headers) => _dio.get(
              '$_apiBaseUrl/v1/account_profiles/'
              '${Uri.encodeComponent(normalizedSlug)}',
              options: Options(headers: headers),
            ),
          );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profile detail response shape.');
      }

      final data = raw['data'];
      if (data is! Map) {
        throw Exception('Account profile detail payload missing data object.');
      }

      final distanceOrigin = await _resolveDistanceOrigin();
      final profiles = _parseProfiles(
        [Map<String, dynamic>.from(data)],
        distanceOrigin: distanceOrigin,
        routeSlugFallback: normalizedSlug,
        allowUnavailableNameFallback: true,
      );
      if (profiles.isEmpty) {
        throw Exception(
          'Account profile detail payload missing required fields.',
        );
      }

      return profiles.first;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load account profile by slug '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  List<AccountProfileModel> _parseProfiles(
    List<dynamic> raw, {
    required CityCoordinate? distanceOrigin,
    String? routeSlugFallback,
    bool allowUnavailableNameFallback = false,
  }) {
    final profiles = <AccountProfileModel>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      try {
        final id = json['id']?.toString().trim() ?? '';
        final slug = _resolvePublicSlug(
          payloadSlug: json['slug']?.toString(),
          routeSlugFallback: routeSlugFallback,
        );
        final name = _resolvePublicVisibleName(
          displayName: json['display_name']?.toString(),
          payloadSlug: json['slug']?.toString(),
          routeSlugFallback: routeSlugFallback,
          allowUnavailableSentinel: allowUnavailableNameFallback,
        );
        final trimmedType = json['profile_type']?.toString().trim() ?? '';
        if (id.isEmpty || slug == null || name == null || trimmedType.isEmpty) {
          continue;
        }
        final tags = _extractTags(json['taxonomy_terms']);
        final agendaEvents = _extractAgendaEvents(json['agenda_occurrences']);
        final galleryGroups = _extractGalleryGroups(json['gallery_groups']);
        final nestedGroups = _extractNestedProfileGroups(
          json['nested_profile_groups'],
        );
        final distanceMeters = _resolveDistanceMeters(
          json,
          distanceOrigin: distanceOrigin,
        );
        final locationCoordinates =
            _parseLocationLatLng(json['location']) ??
            _parseTopLevelLatLng(json);
        final locationAddress = _parseLocationAddress(json);
        ThumbUriValue? avatarValue;
        final avatarUrl = json['avatar_url']?.toString();
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          avatarValue = ThumbUriValue(defaultValue: Uri.parse(avatarUrl))
            ..parse(avatarUrl);
        }
        ThumbUriValue? coverValue;
        final coverUrl = json['cover_url']?.toString();
        if (coverUrl != null && coverUrl.isNotEmpty) {
          coverValue = ThumbUriValue(defaultValue: Uri.parse(coverUrl))
            ..parse(coverUrl);
        }
        DescriptionValue? bioValue;
        final bio = json['bio']?.toString();
        if (bio != null && bio.isNotEmpty) {
          bioValue = DescriptionValue()..parse(bio);
        }
        DescriptionValue? contentValue;
        final content = json['content']?.toString();
        if (content != null && content.isNotEmpty) {
          contentValue = DescriptionValue()..parse(content);
        }
        final publicDetailPath =
            json['public_detail_path']?.toString().trim().isNotEmpty == true
            ? json['public_detail_path']?.toString().trim()
            : null;
        final canOpenPublicDetail =
            json['can_open_public_detail'] == true &&
            publicDetailPath != null &&
            publicDetailPath.isNotEmpty;
        AccountProfileLocationAddressValue? locationAddressValue;
        if (locationAddress != null) {
          locationAddressValue = AccountProfileLocationAddressValue()
            ..parse(locationAddress);
        }
        LatitudeValue? locationLatitudeValue;
        LongitudeValue? locationLongitudeValue;
        if (locationCoordinates != null) {
          locationLatitudeValue = LatitudeValue()
            ..parse(locationCoordinates.$1.toString());
          locationLongitudeValue = LongitudeValue()
            ..parse(locationCoordinates.$2.toString());
        }
        final contactMode = BellugaContactSourceMode.fromRaw(
          json['contact_mode']?.toString(),
        );
        final contactSourceAccountProfileId = _parseNullableText(
          json['contact_source_account_profile_id'],
        );
        final contactChannels = BellugaContactChannelCodec.channelsFromJson(
          json['contact_channels'],
        );
        final effectiveContactChannels =
            BellugaContactChannelCodec.channelsFromJson(
              json['effective_contact_channels'],
            );
        final effectiveContactBubbleChannel =
            BellugaContactChannelCodec.channelFromJson(
              json['effective_contact_bubble_channel'],
            );
        final contactBubbleChannelId = _parseNullableText(
          json['contact_bubble_channel_id'],
        );
        profiles.add(
          AccountProfileModel(
            idValue: MongoIDValue()..parse(id),
            nameValue: TitleValue(minLenght: _publicVisibleNameMinLength)
              ..parse(name),
            slugValue: SlugValue()..parse(slug),
            profileTypeValue: AccountProfileTypeValue(trimmedType),
            avatarValue: avatarValue,
            coverValue: coverValue,
            bioValue: bioValue,
            contentValue: contentValue,
            galleryGroupValues: galleryGroups,
            tagValues: tags
                .map(AccountProfileTagValue.new)
                .toList(growable: false),
            agendaEventViews: agendaEvents,
            nestedProfileGroupValues: nestedGroups,
            distanceMetersValue: AccountProfileDistanceMetersValue(
              distanceMeters,
            ),
            locationAddressValue: locationAddressValue,
            locationLatitudeValue: locationLatitudeValue,
            locationLongitudeValue: locationLongitudeValue,
            canOpenPublicDetailValue: DomainBooleanValue(
              defaultValue: false,
              isRequired: false,
            )..parse(canOpenPublicDetail.toString()),
            publicDetailPathValue: publicDetailPath == null
                ? null
                : AccountProfilePublicDetailPathValue(publicDetailPath),
            contactMode: contactMode,
            contactSourceAccountProfileId: contactSourceAccountProfileId == null
                ? null
                : AccountProfileContactSourceAccountProfileIdValue(
                    contactSourceAccountProfileId,
                  ),
            contactChannelValues: contactChannels,
            contactBubbleChannelId: contactBubbleChannelId == null
                ? null
                : AccountProfileContactChannelIdValue(contactBubbleChannelId),
            effectiveContactChannelValues: effectiveContactChannels,
            effectiveContactBubbleChannelValue: effectiveContactBubbleChannel,
            contactSourceProfile: _parseContactSourceSummary(
              json['contact_source_account_profile'],
            ),
            effectiveContactSourceProfile: _parseContactSourceSummary(
              json['effective_contact_source'],
            ),
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return profiles;
  }

  String? _resolvePublicVisibleName({
    String? displayName,
    String? payloadSlug,
    String? routeSlugFallback,
    bool allowUnavailableSentinel = false,
  }) {
    final normalizedDisplayName = displayName?.trim() ?? '';
    if (normalizedDisplayName.length >= _publicVisibleNameMinLength) {
      return normalizedDisplayName;
    }

    final slugLabel =
        _humanizeSlugLabel(payloadSlug) ??
        _humanizeSlugLabel(routeSlugFallback);
    if (slugLabel != null) {
      return slugLabel;
    }

    return allowUnavailableSentinel ? _publicUnavailableProfileLabel : null;
  }

  String? _parseNullableText(Object? raw) {
    final normalized = raw?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  AccountProfileContactSourceSummary? _parseContactSourceSummary(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final id = _parseNullableText(json['id']);
    final displayName = _parseNullableText(json['display_name']);
    final profileType = _parseNullableText(json['profile_type']);
    if (id == null || displayName == null || profileType == null) {
      return null;
    }
    return AccountProfileContactSourceSummary(
      id: id,
      displayName: displayName,
      slug: _parseNullableText(json['slug']),
      profileType: profileType,
    );
  }

  String? _resolvePublicSlug({String? payloadSlug, String? routeSlugFallback}) {
    final normalizedPayloadSlug = payloadSlug?.trim() ?? '';
    if (normalizedPayloadSlug.isNotEmpty) {
      return normalizedPayloadSlug;
    }

    final normalizedRouteSlug = routeSlugFallback?.trim() ?? '';
    if (normalizedRouteSlug.isNotEmpty) {
      return normalizedRouteSlug;
    }

    return null;
  }

  String? _humanizeSlugLabel(String? rawSlug) {
    final normalizedSlug = rawSlug?.trim() ?? '';
    if (normalizedSlug.isEmpty) {
      return null;
    }

    final normalized = normalizedSlug
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  List<AccountProfileGalleryGroup> _extractGalleryGroups(dynamic raw) {
    if (raw is! List) {
      return const <AccountProfileGalleryGroup>[];
    }

    final groups = <AccountProfileGalleryGroup>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final groupId = json['group_id']?.toString().trim() ?? '';
      final subtitle = json['subtitle']?.toString().trim() ?? '';
      if (groupId.isEmpty || subtitle.isEmpty) {
        continue;
      }

      final items = _extractGalleryItems(json['items']);
      if (items.isEmpty) {
        continue;
      }

      groups.add(
        AccountProfileGalleryGroup(
          groupIdValue: AccountProfileNestedGroupIdValue(groupId),
          subtitleValue: AccountProfileNestedGroupLabelValue(subtitle),
          orderValue: AccountProfileNestedGroupOrderValue(
            _parsePageValue(json['order']) ?? groups.length,
          ),
          items: items,
        ),
      );
    }

    groups.sort((left, right) => left.order.compareTo(right.order));
    return List<AccountProfileGalleryGroup>.unmodifiable(groups);
  }

  List<AccountProfileGalleryItem> _extractGalleryItems(dynamic raw) {
    if (raw is! List) {
      return const <AccountProfileGalleryItem>[];
    }

    final items = <AccountProfileGalleryItem>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final itemId = json['item_id']?.toString().trim() ?? '';
      final imageUrl = json['image_url']?.toString().trim() ?? '';
      final thumbUrl = json['thumb_url']?.toString().trim() ?? '';
      final cardUrl = json['card_url']?.toString().trim() ?? '';
      final modalUrl = json['modal_url']?.toString().trim() ?? '';
      if (itemId.isEmpty ||
          imageUrl.isEmpty ||
          thumbUrl.isEmpty ||
          cardUrl.isEmpty ||
          modalUrl.isEmpty) {
        continue;
      }

      final description = json['description']?.toString().trim();
      items.add(
        AccountProfileGalleryItem(
          itemIdValue: AccountProfileNestedGroupIdValue(itemId),
          descriptionValue: AccountProfileNestedGroupMemberTextValue(
            description == null || description.isEmpty ? '' : description,
          ),
          orderValue: AccountProfileNestedGroupOrderValue(
            _parsePageValue(json['order']) ?? items.length,
          ),
          imageUrlValue: ThumbUriValue(defaultValue: Uri.parse(imageUrl))
            ..parse(imageUrl),
          thumbUrlValue: ThumbUriValue(defaultValue: Uri.parse(thumbUrl))
            ..parse(thumbUrl),
          cardUrlValue: ThumbUriValue(defaultValue: Uri.parse(cardUrl))
            ..parse(cardUrl),
          modalUrlValue: ThumbUriValue(defaultValue: Uri.parse(modalUrl))
            ..parse(modalUrl),
        ),
      );
    }

    items.sort((left, right) => left.order.compareTo(right.order));
    return List<AccountProfileGalleryItem>.unmodifiable(items);
  }

  List<AccountProfileNestedGroup> _extractNestedProfileGroups(dynamic raw) {
    if (raw is! List) {
      return const <AccountProfileNestedGroup>[];
    }

    final groups = <AccountProfileNestedGroup>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final id = (json['id'] ?? json['key'])?.toString().trim() ?? '';
      final label = json['label']?.toString().trim() ?? '';
      if (id.isEmpty || label.isEmpty) {
        continue;
      }
      groups.add(
        AccountProfileNestedGroup(
          idValue: AccountProfileNestedGroupIdValue(id),
          labelValue: AccountProfileNestedGroupLabelValue(label),
          orderValue: AccountProfileNestedGroupOrderValue(
            _parsePageValue(json['order']) ?? groups.length,
          ),
          profiles: _extractNestedGroupMembers(json['profiles']),
        ),
      );
    }

    groups.sort((left, right) => left.order.compareTo(right.order));
    return List<AccountProfileNestedGroup>.unmodifiable(groups);
  }

  List<AccountProfileNestedGroupMember> _extractNestedGroupMembers(
    dynamic raw,
  ) {
    if (raw is! List) {
      return const <AccountProfileNestedGroupMember>[];
    }

    final members = <AccountProfileNestedGroupMember>[];
    final seen = <String>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      try {
        final id = json['id']?.toString().trim() ?? '';
        final slug = json['slug']?.toString().trim() ?? '';
        final displayName = _resolvePublicVisibleName(
          displayName: json['display_name']?.toString(),
          payloadSlug: slug,
        );
        final profileType = json['profile_type']?.toString().trim() ?? '';
        final publicDetailPath =
            json['public_detail_path']?.toString().trim().isNotEmpty == true
            ? json['public_detail_path']?.toString().trim()
            : null;
        final canOpenPublicDetail =
            json['can_open_public_detail'] == true &&
            publicDetailPath != null &&
            publicDetailPath.isNotEmpty;
        if (id.isEmpty ||
            displayName == null ||
            profileType.isEmpty ||
            !seen.add(id)) {
          continue;
        }

        SlugValue? slugValue;
        if (slug.isNotEmpty) {
          slugValue = SlugValue()..parse(slug);
        }

        ThumbUriValue? avatarValue;
        final avatarUrl = json['avatar_url']?.toString().trim();
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          avatarValue = ThumbUriValue(defaultValue: Uri.parse(avatarUrl))
            ..parse(avatarUrl);
        }
        ThumbUriValue? coverValue;
        final coverUrl = json['cover_url']?.toString().trim();
        if (coverUrl != null && coverUrl.isNotEmpty) {
          coverValue = ThumbUriValue(defaultValue: Uri.parse(coverUrl))
            ..parse(coverUrl);
        }

        members.add(
          AccountProfileNestedGroupMember(
            idValue: MongoIDValue()..parse(id),
            nameValue: TitleValue(minLenght: _publicVisibleNameMinLength)
              ..parse(displayName),
            slugValue: slugValue,
            profileTypeValue: AccountProfileTypeValue(profileType),
            avatarValue: avatarValue,
            coverValue: coverValue,
            canOpenPublicDetailValue: DomainBooleanValue(
              defaultValue: false,
              isRequired: false,
            )..parse(canOpenPublicDetail.toString()),
            publicDetailPathValue: publicDetailPath == null
                ? null
                : AccountProfileNestedGroupMemberTextValue(publicDetailPath),
            tagValues: _extractTags(
              json['taxonomy_terms'],
            ).map(AccountProfileTagValue.new).toList(growable: false),
          ),
        );
      } catch (_) {
        continue;
      }
    }

    return List<AccountProfileNestedGroupMember>.unmodifiable(members);
  }

  List<dynamic> _extractDataList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is List) {
      return data;
    }

    final items = payload['items'];
    if (items is List) {
      return items;
    }

    throw Exception('Account profiles payload missing data list.');
  }

  List<String> _extractTags(dynamic raw) {
    if (raw is! List) return const [];
    final tags = <String>[];
    for (final entry in raw) {
      if (entry is Map) {
        final value =
            entry['name']?.toString() ??
            entry['label']?.toString() ??
            entry['value']?.toString();
        if (value != null && value.trim().isNotEmpty) {
          tags.add(value.trim());
        }
      }
    }
    return tags;
  }

  List<PartnerEventView> _extractAgendaEvents(dynamic raw) {
    if (raw is! List) return const [];
    final agendaEvents = <PartnerEventView>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final eventId = json['event_id']?.toString().trim() ?? '';
      final occurrenceId = json['occurrence_id']?.toString().trim() ?? '';
      final slug = json['slug']?.toString().trim() ?? '';
      final title = json['title']?.toString().trim() ?? '';
      final startRaw =
          (json['date_time_start'] ?? json['starts_at'])?.toString().trim() ??
          '';
      if (eventId.isEmpty ||
          occurrenceId.isEmpty ||
          slug.isEmpty ||
          title.isEmpty ||
          startRaw.isEmpty) {
        continue;
      }

      final startDateTimeValue = DateTimeValue(isRequired: true)
        ..parse(startRaw);
      final endRaw =
          (json['date_time_end'] ?? json['ends_at'])?.toString().trim() ?? '';
      final endDateTimeValue = endRaw.isEmpty
          ? null
          : (DateTimeValue(isRequired: true)..parse(endRaw));
      final venueId = _extractAgendaVenueId(json);
      final venueTitle = _extractAgendaVenueTitle(json);
      final eventTypeLabel = _extractAgendaEventTypeLabel(json);
      final locationLabel =
          _extractAgendaLocationLabel(json) ?? venueTitle ?? '';
      final linkedAccountProfiles = _extractAgendaLinkedAccountProfiles(
        json['linked_account_profiles'],
      );
      ThumbUriValue? imageUriValue;
      final imageUrl = _extractAgendaImageUrl(json, linkedAccountProfiles);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        imageUriValue = ThumbUriValue(defaultValue: Uri.parse(imageUrl))
          ..parse(imageUrl);
      }

      agendaEvents.add(
        PartnerEventView(
          eventIdValue: MongoIDValue()..parse(eventId),
          occurrenceIdValue: MongoIDValue()..parse(occurrenceId),
          slugValue: SlugValue()..parse(slug),
          titleValue: partnerProjectionRequiredText(title),
          eventTypeLabelValue: eventTypeLabel == null
              ? null
              : partnerProjectionOptionalText(eventTypeLabel),
          startDateTimeValue: startDateTimeValue,
          endDateTimeValue: endDateTimeValue,
          locationValue: partnerProjectionRequiredText(locationLabel),
          venueIdValue: venueId == null
              ? null
              : (MongoIDValue()..parse(venueId)),
          venueTitleValue: venueTitle == null
              ? null
              : partnerProjectionOptionalText(venueTitle),
          imageUriValue: imageUriValue,
          linkedAccountProfiles: linkedAccountProfiles,
        ),
      );
    }
    return agendaEvents;
  }

  List<PartnerSupportedEntityView> _extractAgendaLinkedAccountProfiles(
    dynamic raw,
  ) {
    if (raw is! List) {
      return const [];
    }

    final linkedAccountProfiles = <PartnerSupportedEntityView>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final displayName =
          (json['display_name'] ?? json['name'])?.toString().trim() ?? '';
      if (displayName.isEmpty) {
        continue;
      }

      final thumb = json['avatar_url']?.toString().trim();
      linkedAccountProfiles.add(
        PartnerSupportedEntityView(
          idValue: (() {
            final id = json['id']?.toString().trim();
            if (id == null || id.isEmpty) {
              return null;
            }
            return MongoIDValue()..parse(id);
          })(),
          titleValue: partnerProjectionRequiredText(displayName),
          thumbValue: thumb == null || thumb.isEmpty
              ? null
              : partnerProjectionOptionalText(thumb),
        ),
      );
    }

    return linkedAccountProfiles;
  }

  String? _extractAgendaVenueId(Map<String, dynamic> json) {
    final rawVenue = json['venue'];
    if (rawVenue is! Map) {
      return null;
    }

    final venue = Map<String, dynamic>.from(rawVenue);
    final value = venue['id']?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? _extractAgendaVenueTitle(Map<String, dynamic> json) {
    final rawVenue = json['venue'];
    if (rawVenue is! Map) {
      return null;
    }

    final venue = Map<String, dynamic>.from(rawVenue);
    final value = (venue['display_name'] ?? venue['name'])?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? _extractAgendaEventTypeLabel(Map<String, dynamic> json) {
    final rawType = json['type'];
    if (rawType is! Map) {
      return null;
    }

    final type = Map<String, dynamic>.from(rawType);
    final value = (type['label'] ?? type['name'] ?? type['title'])
        ?.toString()
        .trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? _extractAgendaLocationLabel(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    if (rawLocation is String) {
      final value = rawLocation.trim();
      return value.isEmpty ? null : value;
    }
    if (rawLocation is! Map) {
      return null;
    }

    final location = Map<String, dynamic>.from(rawLocation);
    const keys = <String>[
      'label',
      'display_name',
      'formatted_address',
      'address',
      'name',
    ];
    for (final key in keys) {
      final value = location[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String? _extractAgendaImageUrl(
    Map<String, dynamic> json,
    List<PartnerSupportedEntityView> linkedAccountProfiles,
  ) {
    final rawThumb = json['thumb'];
    if (rawThumb is Map) {
      final thumb = Map<String, dynamic>.from(rawThumb);
      final data = thumb['data'];
      if (data is Map) {
        final url = data['url']?.toString().trim();
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }

    for (final counterpart in linkedAccountProfiles) {
      final imageUrl = counterpart.thumb?.trim();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }

    final rawVenue = json['venue'];
    if (rawVenue is Map) {
      final venue = Map<String, dynamic>.from(rawVenue);
      for (final key in const ['hero_image_url', 'logo_url']) {
        final imageUrl = venue[key]?.toString().trim();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
    }

    return null;
  }

  int? _parsePageValue(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    switch (value?.toString().trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
        return true;
      case '0':
      case 'false':
      case 'no':
        return false;
      default:
        return false;
    }
  }

  double? _resolveDistanceMeters(
    Map<String, dynamic> json, {
    required CityCoordinate? distanceOrigin,
  }) {
    final directDistance = _parseDirectDistanceMeters(json);
    if (directDistance != null) {
      return directDistance;
    }

    final location =
        _parseLocationLatLng(json['location']) ?? _parseTopLevelLatLng(json);
    if (location == null) {
      return null;
    }

    if (distanceOrigin == null) {
      return null;
    }

    return haversineDistanceMeters(
      coordinateA: distanceOrigin,
      coordinateB: CityCoordinate.fromLatLng(LatLng(location.$1, location.$2)),
    ).value;
  }

  String? _parseLocationAddress(Map<String, dynamic> json) {
    final topLevelAddress = json['address']?.toString().trim();
    if (topLevelAddress != null && topLevelAddress.isNotEmpty) {
      return topLevelAddress;
    }

    final rawLocation = json['location'];
    if (rawLocation is! Map) {
      return null;
    }

    final location = Map<String, dynamic>.from(rawLocation);
    const addressKeys = <String>[
      'address',
      'label',
      'formatted_address',
      'display_name',
      'name',
    ];
    for (final key in addressKeys) {
      final value = location[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  double? _parseDirectDistanceMeters(Map<String, dynamic> json) {
    const meterKeys = <String>[
      'distance_meters',
      'distanceMeters',
      'distance_in_meters',
      'distanceMetersValue',
    ];
    for (final key in meterKeys) {
      final value = _parseDouble(json[key]);
      if (value != null) {
        return value;
      }
    }

    final distanceKm =
        _parseDouble(json['distance_km']) ?? _parseDouble(json['distanceKm']);
    if (distanceKm != null) {
      return distanceKm * 1000;
    }
    return null;
  }

  Future<CityCoordinate?> _resolveEffectiveOriginCoordinate() async {
    final locationOriginService = _resolvedLocationOriginService;
    if (locationOriginService == null) {
      return null;
    }
    final resolution = await locationOriginService.resolve(
      LocationOriginResolutionRequestFactory.create(warmUpIfPossible: true),
    );
    return resolution.effectiveCoordinate;
  }

  Future<CityCoordinate?> _resolveDistanceOrigin() async {
    return _resolveEffectiveOriginCoordinate();
  }

  (double, double)? _parseLocationLatLng(dynamic rawLocation) {
    if (rawLocation is List) {
      return _parseCoordinatesPayload(rawLocation);
    }
    if (rawLocation is! Map) {
      return null;
    }
    final location = Map<String, dynamic>.from(rawLocation);
    final directLatLng = _parseLatLngFromMap(location);
    if (directLatLng != null) {
      return directLatLng;
    }

    final geoLatLng = _parseCoordinatesPayload(location['geo']);
    if (geoLatLng != null) {
      return geoLatLng;
    }

    final locationCoordinates = _parseCoordinatesPayload(
      location['coordinates'],
    );
    if (locationCoordinates != null) {
      return locationCoordinates;
    }

    return null;
  }

  (double, double)? _parseTopLevelLatLng(Map<String, dynamic> json) {
    final topLevelLatLng = _parseLatLngFromMap(json);
    if (topLevelLatLng != null) {
      return topLevelLatLng;
    }
    return _parseCoordinatesPayload(json['coordinates']);
  }

  (double, double)? _parseLatLngFromMap(Map<String, dynamic> map) {
    final lat = _parseDouble(map['lat']) ?? _parseDouble(map['latitude']);
    final lng =
        _parseDouble(map['lng']) ??
        _parseDouble(map['lon']) ??
        _parseDouble(map['longitude']);
    if (lat != null && lng != null) {
      return (lat, lng);
    }
    return null;
  }

  (double, double)? _parseCoordinatesPayload(dynamic coordinatesRaw) {
    if (coordinatesRaw is List && coordinatesRaw.length >= 2) {
      final coordLng = _parseDouble(coordinatesRaw[0]);
      final coordLat = _parseDouble(coordinatesRaw[1]);
      if (coordLat != null && coordLng != null) {
        return (coordLat, coordLng);
      }
      return null;
    }
    if (coordinatesRaw is Map) {
      final coordinates = Map<String, dynamic>.from(coordinatesRaw);
      final latLng = _parseLatLngFromMap(coordinates);
      if (latLng != null) {
        return latLng;
      }
      return _parseCoordinatesPayload(coordinates['coordinates']);
    }
    return null;
  }

  double? _parseDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      final normalized = raw.trim().replaceAll(',', '.');
      if (normalized.isEmpty) {
        return null;
      }
      return double.tryParse(normalized);
    }
    return null;
  }
}
