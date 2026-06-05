import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_member_text_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class AccountProfileNestedGroupMember {
  AccountProfileNestedGroupMember({
    required this.idValue,
    required this.nameValue,
    required this.profileTypeValue,
    this.slugValue,
    this.avatarValue,
    this.coverValue,
    DomainBooleanValue? canOpenPublicDetailValue,
    this.publicDetailPathValue,
    List<AccountProfileTagValue>? tagValues,
  })  : canOpenPublicDetailValue = DomainBooleanValue(
          defaultValue: false,
          isRequired: false,
        )..parse((canOpenPublicDetailValue?.value ?? false).toString()),
        tagValues = List<AccountProfileTagValue>.unmodifiable(
          tagValues ?? const <AccountProfileTagValue>[],
        );

  final MongoIDValue idValue;
  final TitleValue nameValue;
  final SlugValue? slugValue;
  final AccountProfileTypeValue profileTypeValue;
  final ThumbUriValue? avatarValue;
  final ThumbUriValue? coverValue;
  final DomainBooleanValue canOpenPublicDetailValue;
  final AccountProfileNestedGroupMemberTextValue? publicDetailPathValue;
  final List<AccountProfileTagValue> tagValues;

  String get id => idValue.value;
  String get name => nameValue.value;
  String get slug => slugValue?.value ?? '';
  String get profileType => profileTypeValue.value;
  Uri? get avatarUri => avatarValue?.value;
  String? get avatarUrl => avatarUri?.toString();
  Uri? get coverUri => coverValue?.value;
  String? get coverUrl => coverUri?.toString();
  bool get canOpenPublicDetail => canOpenPublicDetailValue.value;
  String? get publicDetailPath =>
      publicDetailPathValue?.value.trim().isEmpty == true
          ? null
          : publicDetailPathValue?.value.trim();
  List<AccountProfileTagValue> get tags =>
      List<AccountProfileTagValue>.unmodifiable(tagValues);
}
