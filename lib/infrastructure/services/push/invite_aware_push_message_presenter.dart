import 'package:flutter/material.dart';
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
  }) : _contextProvider = contextProvider;

  final BuildContext? Function()? _contextProvider;

  @override
  Future<void> present({
    required MessageData messageData,
    required PushActionReporter reportAction,
    String? deviceId,
  }) async {
    if (shouldSkipGenericPresentation(messageData)) {
      _showInviteSpecificSignal(messageData);
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

  void _showInviteSpecificSignal(MessageData messageData) {
    final context = _contextProvider?.call();
    if (context == null || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    final title = messageData.title.value.trim();
    final body = messageData.body.value.trim();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(body),
              ],
            ],
          ),
        ),
      );
  }
}
