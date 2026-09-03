import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_validation_message_value.dart';

abstract final class AccountProfileExternalLinkRegistry {
  static AccountProfileExternalLink validateMutation({
    required AccountProfileExternalLinkIdValue id,
    required AccountProfileExternalLinkType type,
    required AccountProfileExternalLinkUrlValue url,
    AccountProfileExternalLinkLabelValue? label,
  }) {
    if (!type.accepts(url)) {
      throw AccountProfileExternalLinkValidationException(
        field: AccountProfileExternalLinkValidationField.url,
        messageValue: AccountProfileExternalLinkValidationMessageValue(
          'The external link host does not match the selected type.',
        ),
      );
    }
    if (type != AccountProfileExternalLinkType.website) {
      if (label != null) {
        throw AccountProfileExternalLinkValidationException(
          field: AccountProfileExternalLinkValidationField.label,
          messageValue: AccountProfileExternalLinkValidationMessageValue(
            'A label is only allowed for website links.',
          ),
        );
      }
      return AccountProfileExternalLink(
        idValue: id,
        type: type,
        urlValue: url,
        labelValue: AccountProfileExternalLinkLabelValue(type.semanticLabel),
      );
    }
    if (label == null) {
      throw AccountProfileExternalLinkValidationException(
        field: AccountProfileExternalLinkValidationField.label,
        messageValue: AccountProfileExternalLinkValidationMessageValue(
          'A website label is required.',
        ),
      );
    }
    return AccountProfileExternalLink(
      idValue: id,
      type: type,
      urlValue: url,
      labelValue: label,
    );
  }
}
