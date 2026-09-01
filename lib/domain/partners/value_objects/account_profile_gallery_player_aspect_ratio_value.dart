import 'package:value_object_pattern/value_object.dart';

class AccountProfileGalleryPlayerAspectRatioValue extends ValueObject<double> {
  AccountProfileGalleryPlayerAspectRatioValue([Object? raw])
    : super(defaultValue: 16 / 9, isRequired: false) {
    parse(raw?.toString());
  }

  @override
  double doParse(String? parseValue) {
    final parsed = double.tryParse((parseValue ?? '').trim());
    return parsed != null && parsed > 0 ? parsed : defaultValue;
  }
}
