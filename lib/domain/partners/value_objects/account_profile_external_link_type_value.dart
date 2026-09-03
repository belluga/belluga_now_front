import 'package:belluga_now/domain/partners/account_profile_external_link_type.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

final class AccountProfileExternalLinkTypeValue
    extends ValueObject<AccountProfileExternalLinkType> {
  AccountProfileExternalLinkTypeValue(String raw)
    : super(
        defaultValue: AccountProfileExternalLinkType.instagram,
        isRequired: true,
      ) {
    parse(raw);
  }

  @override
  AccountProfileExternalLinkType doParse(String? parseValue) {
    final normalized = parseValue?.trim();
    for (final type in AccountProfileExternalLinkType.values) {
      if (type.wireValue == normalized) return type;
    }
    throw InvalidValueException();
  }
}
