class InviteRateLimitsValue {
  InviteRateLimitsValue([Map<String, int>? raw])
      : value = Map<String, int>.unmodifiable(raw ?? const <String, int>{});

  final Map<String, int> value;
}
