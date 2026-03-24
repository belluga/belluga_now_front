import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_string_list_value.dart';

typedef TenantAdminMapFilterQueryPrimString = String;
typedef TenantAdminMapFilterQueryPrimInt = int;
typedef TenantAdminMapFilterQueryPrimBool = bool;
typedef TenantAdminMapFilterQueryPrimDouble = double;
typedef TenantAdminMapFilterQueryPrimDateTime = DateTime;
typedef TenantAdminMapFilterQueryPrimDynamic = dynamic;

class TenantAdminMapFilterQuery {
  TenantAdminMapFilterQuery({
    this.source,
    List<TenantAdminMapFilterQueryPrimString> types =
        const <TenantAdminMapFilterQueryPrimString>[],
    List<TenantAdminMapFilterQueryPrimString> taxonomy =
        const <TenantAdminMapFilterQueryPrimString>[],
  })  : typeValues = TenantAdminLowercaseStringListValue(types),
        taxonomyValues = TenantAdminLowercaseStringListValue(taxonomy);

  final TenantAdminMapFilterSource? source;
  final TenantAdminLowercaseStringListValue typeValues;
  final TenantAdminLowercaseStringListValue taxonomyValues;

  List<TenantAdminMapFilterQueryPrimString> get types => typeValues.value;
  List<TenantAdminMapFilterQueryPrimString> get taxonomy =>
      taxonomyValues.value;

  TenantAdminMapFilterQueryPrimBool get isEmpty =>
      source == null && typeValues.isEmpty && taxonomyValues.isEmpty;

  TenantAdminMapFilterQuery copyWith({
    TenantAdminMapFilterSource? source,
    List<TenantAdminMapFilterQueryPrimString>? types,
    List<TenantAdminMapFilterQueryPrimString>? taxonomy,
    TenantAdminMapFilterQueryPrimBool clearSource = false,
  }) {
    return TenantAdminMapFilterQuery(
      source: clearSource ? null : (source ?? this.source),
      types: types ?? this.types,
      taxonomy: taxonomy ?? this.taxonomy,
    );
  }

  Map<TenantAdminMapFilterQueryPrimString, TenantAdminMapFilterQueryPrimDynamic>
      toJson() {
    return {
      if (source != null) 'source': source!.apiValue,
      if (types.isNotEmpty) 'types': types,
      if (taxonomy.isNotEmpty) 'taxonomy': taxonomy,
    };
  }
}
