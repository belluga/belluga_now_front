import 'package:value_object_pattern/value_object.dart';

class AccountProfileDistanceMetersValue extends ValueObject<double?> {
  AccountProfileDistanceMetersValue([double? raw])
    : super(defaultValue: raw, isRequired: false) {
    set(raw);
  }

  @override
  double? doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }
}
