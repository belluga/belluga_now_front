class LandlordAuthLoginPayload {
  const LandlordAuthLoginPayload({
    required this.token,
    required this.userId,
  });

  final String token;
  final String? userId;
}
