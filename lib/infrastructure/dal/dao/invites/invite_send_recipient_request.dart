class InviteSendRecipientRequest {
  const InviteSendRecipientRequest({
    required this.receiverAccountProfileId,
  });

  final String receiverAccountProfileId;

  Map<String, dynamic> toJson() {
    return {
      'receiver_account_profile_id': receiverAccountProfileId,
    };
  }
}
