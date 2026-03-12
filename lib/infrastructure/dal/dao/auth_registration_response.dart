class AuthRegistrationResponse {
  const AuthRegistrationResponse({
    required this.token,
    this.userId,
    this.identityState,
    this.expiresAt,
  });

  final String token;
  final String? userId;
  final String? identityState;
  final String? expiresAt;
}
