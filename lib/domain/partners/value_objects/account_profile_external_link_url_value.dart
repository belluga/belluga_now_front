import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

final class AccountProfileExternalLinkUrlValue extends ValueObject<Uri> {
  AccountProfileExternalLinkUrlValue(String raw)
    : super(defaultValue: Uri(), isRequired: true) {
    parse(raw);
  }

  @override
  Uri doParse(String? parseValue) {
    final raw = parseValue?.trim() ?? '';
    final uri = Uri.tryParse(raw);
    if (raw.isEmpty ||
        raw.length > 2048 ||
        uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.trim().isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw InvalidValueException();
    }
    return uri;
  }
}
