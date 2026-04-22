import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_contract_text_value.dart';
import 'package:value_object_pattern/value_object.dart';

class AccountProfilesRepositoryTaxonomyFilter extends ValueObject<String> {
  AccountProfilesRepositoryTaxonomyFilter({
    required this.type,
    required this.term,
  }) : super(defaultValue: '', isRequired: false) {
    parse('${type.value}:${term.value}');
  }

  factory AccountProfilesRepositoryTaxonomyFilter.fromRaw({
    required Object? type,
    required Object? value,
  }) {
    return AccountProfilesRepositoryTaxonomyFilter(
      type: AccountProfilesRepositoryContractTextValue.fromRaw(type),
      term: AccountProfilesRepositoryContractTextValue.fromRaw(value),
    );
  }

  final AccountProfilesRepositoryContractTextValue type;
  final AccountProfilesRepositoryContractTextValue term;

  bool get isValid => type.value.isNotEmpty && term.value.isNotEmpty;

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}
