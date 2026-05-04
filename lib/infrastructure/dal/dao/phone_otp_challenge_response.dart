class PhoneOtpChallengeResponse {
  const PhoneOtpChallengeResponse({
    required this.challengeId,
    required this.phone,
    required this.deliveryChannel,
    this.expiresAt,
    this.resendAvailableAt,
  });

  final String challengeId;
  final String phone;
  final String deliveryChannel;
  final String? expiresAt;
  final String? resendAvailableAt;

  factory PhoneOtpChallengeResponse.fromJson(Map<String, dynamic> data) {
    final challengeId = data['challenge_id']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final delivery = data['delivery'];
    final deliveryMap = delivery is Map
        ? Map<String, dynamic>.from(delivery)
        : <String, dynamic>{};
    if (challengeId.isEmpty || phone.isEmpty) {
      throw Exception('OTP challenge response is missing required fields.');
    }

    return PhoneOtpChallengeResponse(
      challengeId: challengeId,
      phone: phone,
      deliveryChannel: deliveryMap['channel']?.toString() ?? 'whatsapp',
      expiresAt: data['expires_at']?.toString(),
      resendAvailableAt: data['resend_available_at']?.toString(),
    );
  }
}
