enum InviteNextStep {
  none,
  freeConfirmationCreated,
  reservationRequired,
  commitmentChoiceRequired,
  openAppToContinue,
}

extension InviteNextStepApiMapper on InviteNextStep {
  static InviteNextStep parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
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
