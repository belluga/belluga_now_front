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
    if (_shouldSkipGenericPresentation(messageData)) {
      return;
    }

    await super.present(
      messageData: messageData,
      reportAction: reportAction,
      deviceId: deviceId,
    );
  }

  bool _shouldSkipGenericPresentation(MessageData messageData) {
    return messageData.steps.isEmpty && messageData.buttons.isEmpty;
  }
}
