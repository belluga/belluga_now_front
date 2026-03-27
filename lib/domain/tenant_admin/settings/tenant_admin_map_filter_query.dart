import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_string_list_value.dart';

class TenantAdminMapFilterQuery {
  TenantAdminMapFilterQuery({
    this.source,
    TenantAdminLowercaseStringListValue? typeValues,
    TenantAdminLowercaseStringListValue? taxonomyValues,
  })  : typeValues = typeValues ?? TenantAdminLowercaseStringListValue(),
        taxonomyValues =
            taxonomyValues ?? TenantAdminLowercaseStringListValue();

  final TenantAdminMapFilterSource? source;
  final TenantAdminLowercaseStringListValue typeValues;
  final TenantAdminLowercaseStringListValue taxonomyValues;

  List<String> get types => typeValues.value;
  List<String> get taxonomy => taxonomyValues.value;

  bool get isEmpty =>
      source == null && typeValues.isEmpty && taxonomyValues.isEmpty;

  TenantAdminMapFilterQuery copyWith({
    TenantAdminMapFilterSource? source,
    TenantAdminLowercaseStringListValue? typeValues,
    TenantAdminLowercaseStringListValue? taxonomyValues,
    TenantAdminFlagValue? clearSourceValue,
  }) {
    final clearSource = clearSourceValue?.value ?? false;
    return TenantAdminMapFilterQuery(
      source: clearSource ? null : (source ?? this.source),
      typeValues: typeValues ?? this.typeValues,
      taxonomyValues: taxonomyValues ?? this.taxonomyValues,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (source != null) 'source': source!.apiValue,
      if (types.isNotEmpty) 'types': types,
      if (taxonomy.isNotEmpty) 'taxonomy': taxonomy,
    };
  }
}
