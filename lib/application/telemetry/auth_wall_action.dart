final class AuthWallAction {
  const AuthWallAction({
    required this.actionType,
    this.payload,
  });

  final String actionType;
  final Map<String, dynamic>? payload;
}
