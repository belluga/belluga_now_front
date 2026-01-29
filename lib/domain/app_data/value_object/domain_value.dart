import 'package:belluga_now/domain/value_objects/url_required_value.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';

class DomainValue extends URIRequiredValue {
  DomainValue({
    Uri? defaultValue,
    super.isRequired = true,
  }) : super(defaultValue: defaultValue ?? Uri.parse('https://localhost'));

  /// Normalizes host-like inputs into an absolute https URI if a scheme is absent.
  static String coerceRaw(dynamic raw) {
    if (raw is Map) {
      final candidate = raw['path'] ??
          raw['domain'] ??
          raw['url'] ??
          raw['href'] ??
          raw['host'];
      if (candidate is String) {
        return candidate;
      }
    }
    if (raw is Uri) return raw.toString();
    return raw?.toString() ?? '';
  }

  @override
  Uri doParse(String? parseValue) {
    final candidate = (parseValue ?? defaultValue.toString()).trim();
    if (candidate.isEmpty) {
      throw RequiredValueException();
    }
    final normalized = candidate.contains('://') ? candidate : 'https://$candidate';
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw InvalidValueException();
    }
    return uri;
  }
}
