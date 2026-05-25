import 'package:value_object_pattern/value_object.dart';

class SelfProfileInvitesAcceptedCountValue extends ValueObject<int> {
  SelfProfileInvitesAcceptedCountValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  @override
  int doParse(String? parseValue) => int.tryParse(parseValue ?? '') ?? 0;
}
