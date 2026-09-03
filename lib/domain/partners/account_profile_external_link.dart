import 'package:belluga_now/domain/partners/account_profile_external_link_type.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_id_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_label_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_url_value.dart';

export 'package:belluga_now/domain/partners/account_profile_external_link_registry.dart';
export 'package:belluga_now/domain/partners/account_profile_external_link_type.dart';
export 'package:belluga_now/domain/partners/account_profile_external_link_validation_exception.dart';
export 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_id_value.dart';
export 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_label_value.dart';
export 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_type_value.dart';
export 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_url_value.dart';

final class AccountProfileExternalLink {
  const AccountProfileExternalLink({
    required this.idValue,
    required this.type,
    required this.urlValue,
    required this.labelValue,
  });

  final AccountProfileExternalLinkIdValue idValue;
  final AccountProfileExternalLinkType type;
  final AccountProfileExternalLinkUrlValue urlValue;
  final AccountProfileExternalLinkLabelValue labelValue;

  String get id => idValue.value;
  Uri get url => urlValue.value;
  String get label => labelValue.value;
}
