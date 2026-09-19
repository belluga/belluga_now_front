import 'package:value_object_pattern/value_object.dart';

class ProfileTypeLocationPolicyValue extends ValueObject<String> {
  ProfileTypeLocationPolicyValue([String raw = ''])
    : super(defaultValue: '', isRequired: false) {
    parse(raw);
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }

  bool get allowsLocation => value == 'optional' || value == 'required';

  bool get requiresLocation => value == 'required';
}
