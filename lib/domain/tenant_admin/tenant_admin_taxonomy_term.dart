export 'value_objects/tenant_admin_taxonomy_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminTaxonomyTerm {
  TenantAdminTaxonomyTerm({
    required this.typeValue,
    required this.valueField,
    TenantAdminOptionalTextValue? nameValue,
    TenantAdminOptionalTextValue? taxonomyNameValue,
    TenantAdminOptionalTextValue? labelValue,
  })  : nameValue = nameValue ?? TenantAdminOptionalTextValue(),
        taxonomyNameValue = taxonomyNameValue ?? TenantAdminOptionalTextValue(),
        labelValue = labelValue ?? TenantAdminOptionalTextValue();

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue valueField;
  final TenantAdminOptionalTextValue nameValue;
  final TenantAdminOptionalTextValue taxonomyNameValue;
  final TenantAdminOptionalTextValue labelValue;

  String get type => typeValue.value;
  String get value => valueField.value;
  String get name => nameValue.value;
  String get taxonomyName => taxonomyNameValue.value;
  String get label => labelValue.value;
  String get displayLabel {
    final displayName = name.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final compatibilityLabel = label.trim();
    if (compatibilityLabel.isNotEmpty) {
      return compatibilityLabel;
    }
    return value;
  }
}
