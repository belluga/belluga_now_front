import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class AppDataHrefValue extends ValueObject<String> {
  AppDataHrefValue({
    super.defaultValue = '',
    super.isRequired = true,
  });

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();

  @override
  void validate(String? newValue) {
    final normalized = (newValue ?? '').trim();
    if (normalized.isEmpty) {
      throw RequiredValueException();
    }

    final parsed = Uri.tryParse(normalized);
    if (parsed == null || !parsed.hasScheme || parsed.host.trim().isEmpty) {
      throw InvalidValueException();
    }
  }
}
