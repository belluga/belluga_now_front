import 'package:belluga_now/domain/invites/value_objects/invite_next_step_raw_value.dart';

enum InviteNextStep {
  none,
  freeConfirmationCreated,
  reservationRequired,
  commitmentChoiceRequired,
  openAppToContinue,
}

extension InviteNextStepApiMapper on InviteNextStep {
  static InviteNextStep parse(InviteNextStepRawValue? raw) {
    switch (raw?.value.trim().toLowerCase()) {
      case 'free_confirmation_created':
        return InviteNextStep.freeConfirmationCreated;
      case 'reservation_required':
        return InviteNextStep.reservationRequired;
      case 'commitment_choice_required':
        return InviteNextStep.commitmentChoiceRequired;
      case 'open_app_to_continue':
        return InviteNextStep.openAppToContinue;
      default:
        return InviteNextStep.none;
    }
  }
}
