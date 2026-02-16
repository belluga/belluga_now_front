import 'package:flutter/services.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_slug_utils.dart';

final RegExp _tenantAdminSlugPattern = RegExp(r'^[a-z0-9]+(?:[-_][a-z0-9]+)*$');
final RegExp _tenantAdminHexColorPattern = RegExp(r'^#(?:[0-9a-fA-F]{6})$');

final List<TextInputFormatter> tenantAdminCoordinateInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]')),
];

final List<TextInputFormatter> tenantAdminSlugInputFormatters = [
  _TenantAdminSlugInputFormatter(),
];

double? tenantAdminParseLatitude(String? raw) {
  return _tenantAdminParseCoordinateWithValueObject(
    raw: raw,
    parser: (normalized) => LatitudeValue()..parse(normalized),
    valueExtractor: (valueObject) => valueObject.value,
  );
}

double? tenantAdminParseLongitude(String? raw) {
  return _tenantAdminParseCoordinateWithValueObject(
    raw: raw,
    parser: (normalized) => LongitudeValue()..parse(normalized),
    valueExtractor: (valueObject) => valueObject.value,
  );
}

double? _tenantAdminParseCoordinateWithValueObject<T>({
  required String? raw,
  required T Function(String normalized) parser,
  required double Function(T valueObject) valueExtractor,
}) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  final normalized = trimmed.replaceAll(',', '.');
  try {
    final valueObject = parser(normalized);
    return valueExtractor(valueObject);
  } on Exception {
    return null;
  }
}

List<String> tenantAdminParseTokenList(String raw) {
  final seen = <String>{};
  final ordered = <String>[];
  for (final value in raw.split(',')) {
    final token = value.trim();
    if (token.isEmpty) {
      continue;
    }
    final normalized = token.toLowerCase();
    if (seen.contains(normalized)) {
      continue;
    }
    seen.add(normalized);
    ordered.add(token);
  }
  return ordered;
}

String tenantAdminJoinTokenList(List<String> tokens) =>
    tenantAdminParseTokenList(tokens.join(',')).join(', ');

String? tenantAdminValidateRequiredSlug(
  String? value, {
  required String requiredMessage,
  String invalidMessage = 'Slug invalido.',
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return requiredMessage;
  }
  if (!_tenantAdminSlugPattern.hasMatch(trimmed)) {
    return invalidMessage;
  }
  return null;
}

String? tenantAdminValidateOptionalHexColor(
  String? value, {
  String invalidMessage = 'Cor invalida. Use #RRGGBB.',
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  if (!_tenantAdminHexColorPattern.hasMatch(trimmed)) {
    return invalidMessage;
  }
  return null;
}

class _TenantAdminSlugInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = tenantAdminSlugify(newValue.text);
    final offset = normalized.length;
    return newValue.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }
}
