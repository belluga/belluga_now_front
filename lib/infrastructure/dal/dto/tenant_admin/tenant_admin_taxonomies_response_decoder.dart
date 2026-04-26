import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_definition_dto.dart';

class TenantAdminTaxonomiesResponseDecoder {
  const TenantAdminTaxonomiesResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  TenantAdminTaxonomyDTO decodeTaxonomyItem(Object? rawResponse) {
    return TenantAdminTaxonomyDTO.fromJson(
      _envelopeDecoder.decodeItemMap(
        rawResponse,
        label: 'taxonomy',
      ),
    );
  }

  List<TenantAdminTaxonomyDTO> decodeTaxonomyList(Object? rawResponse) {
    return _envelopeDecoder
        .decodeListMap(
          rawResponse,
          label: 'taxonomies',
        )
        .map(TenantAdminTaxonomyDTO.fromJson)
        .toList(growable: false);
  }

  TenantAdminTaxonomyTermDefinitionDTO decodeTermItem(Object? rawResponse) {
    return TenantAdminTaxonomyTermDefinitionDTO.fromJson(
      _envelopeDecoder.decodeItemMap(
        rawResponse,
        label: 'taxonomy term',
      ),
    );
  }

  List<TenantAdminTaxonomyTermDefinitionDTO> decodeTermList(
    Object? rawResponse,
  ) {
    return _envelopeDecoder
        .decodeListMap(
          rawResponse,
          label: 'taxonomy terms',
        )
        .map(TenantAdminTaxonomyTermDefinitionDTO.fromJson)
        .toList(growable: false);
  }

  Map<String, List<TenantAdminTaxonomyTermDefinitionDTO>>
      decodeTermsByTaxonomyId(Object? rawResponse) {
    final rawMap = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'taxonomy terms by taxonomy',
      fallbackToRoot: false,
      emptyWhenDataIsNotMap: true,
    );
    return rawMap.map((taxonomyId, rawTerms) {
      final terms = rawTerms is List
          ? rawTerms
              .whereType<Map>()
              .map(
                (entry) => TenantAdminTaxonomyTermDefinitionDTO.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false)
          : const <TenantAdminTaxonomyTermDefinitionDTO>[];
      return MapEntry(taxonomyId, terms);
    });
  }
}
