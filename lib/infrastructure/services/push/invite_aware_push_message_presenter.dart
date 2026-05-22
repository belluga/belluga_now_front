import 'package:flutter/foundation.dart';
import 'package:push_handler/push_handler.dart';

class InviteAwarePushMessagePresenter extends PushMessagePresenter {
  InviteAwarePushMessagePresenter({
    super.contextProvider,
    super.navigationResolver,
    super.gatekeeper,
    super.optionsBuilder,
    super.onStepSubmit,
    super.stepValidator,
    super.onCustomAction,
  });

  @override
  Future<void> present({
    required MessageData messageData,
    required PushActionReporter reportAction,
    String? deviceId,
  }) async {
    if (shouldSkipGenericPresentation(messageData)) {
      return;
    }

    await super.present(
      messageData: messageData,
      reportAction: reportAction,
      deviceId: deviceId,
    );
  }

  @visibleForTesting
  bool shouldSkipGenericPresentation(MessageData messageData) {
    if (messageData.steps.isNotEmpty || messageData.buttons.isNotEmpty) {
      return false;
    }

    // Until push_handler surfaces the raw push payload to the presenter, the
    // invite copy contract is the narrowest discriminator available here.
    final title = messageData.title.value.trim().toLowerCase();

    return title == 'seu convite foi aceito' ||
        title == 'voce recebeu um convite' ||
        title.startsWith('convite para ');
  }
}
