import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

final class TenantAdminAccountProfileExternalLinkDraft {
  TenantAdminAccountProfileExternalLinkDraft({
    required this.accountProfileId,
    required this.routeGeneration,
    AccountProfileExternalLink? existingLink,
    AccountProfileExternalLinkType? initialType,
  }) : externalLinkId = existingLink?.id,
       selectedTypeStreamValue = StreamValue<AccountProfileExternalLinkType>(
         defaultValue:
             existingLink?.type ??
             initialType ??
             AccountProfileExternalLinkType.instagram,
       ) {
    urlController.text = existingLink?.url.toString() ?? '';
    labelController.text =
        existingLink?.type == AccountProfileExternalLinkType.website
        ? existingLink?.label ?? ''
        : '';
    _initialType = selectedTypeStreamValue.value;
    _initialUrl = urlController.text;
    _initialLabel = labelController.text;
    urlController.addListener(recomputeInputState);
    labelController.addListener(recomputeInputState);
    recomputeInputState();
  }

  final String accountProfileId;
  final int routeGeneration;
  final String? externalLinkId;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController labelController = TextEditingController();
  final StreamValue<AccountProfileExternalLinkType> selectedTypeStreamValue;
  final StreamValue<bool> busyStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<bool> requiresReloadStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<bool> dirtyStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<bool> canSubmitStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  late final AccountProfileExternalLinkType _initialType;
  late final String _initialUrl;
  late final String _initialLabel;
  bool _isDisposed = false;

  bool get isEditing => externalLinkId != null;

  void selectType(AccountProfileExternalLinkType type) {
    selectedTypeStreamValue.addValue(type);
    if (type != AccountProfileExternalLinkType.website) {
      labelController.clear();
    }
    recomputeInputState();
    setError(null);
  }

  void setBusy(bool value) => busyStreamValue.addValue(value);

  void setRequiresReload(bool value) =>
      requiresReloadStreamValue.addValue(value);

  void setError(String? value) => errorStreamValue.addValue(value);

  void recomputeInputState() {
    final selectedType = selectedTypeStreamValue.value;
    dirtyStreamValue.addValue(
      selectedType != _initialType ||
          urlController.text != _initialUrl ||
          labelController.text != _initialLabel,
    );
    try {
      AccountProfileExternalLinkRegistry.validateMutation(
        id: AccountProfileExternalLinkIdValue(externalLinkId ?? 'new-link'),
        type: selectedType,
        url: AccountProfileExternalLinkUrlValue(urlController.text),
        label: selectedType == AccountProfileExternalLinkType.website
            ? AccountProfileExternalLinkLabelValue(labelController.text)
            : null,
      );
      canSubmitStreamValue.addValue(true);
    } on Object {
      canSubmitStreamValue.addValue(false);
    }
  }

  void acceptDiscard() {
    dirtyStreamValue.addValue(false);
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    urlController.dispose();
    labelController.dispose();
    selectedTypeStreamValue.dispose();
    busyStreamValue.dispose();
    requiresReloadStreamValue.dispose();
    errorStreamValue.dispose();
    dirtyStreamValue.dispose();
    canSubmitStreamValue.dispose();
  }
}

enum TenantAdminExternalLinkMutationOutcome {
  saved,
  deleted,
  capabilityDisabled,
  failed,
  ignored,
}
