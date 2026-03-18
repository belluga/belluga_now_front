import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_value.dart';

class TenantAdminSha256FingerprintListValue {
  TenantAdminSha256FingerprintListValue([Iterable<String>? rawValues])
      : _value = List<String>.unmodifiable(_sanitize(rawValues));

  final List<String> _value;

  List<String> get value => _value;

  bool get isEmpty => _value.isEmpty;

  static List<String> _sanitize(Iterable<String>? rawValues) {
    if (rawValues == null) {
      return const <String>[];
    }

    final result = <String>[];
    final seen = <String>{};
    for (final raw in rawValues) {
      final fingerprint = TenantAdminSha256FingerprintValue()..parse(raw);
      final normalized = fingerprint.value;
      if (!seen.add(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }
}
