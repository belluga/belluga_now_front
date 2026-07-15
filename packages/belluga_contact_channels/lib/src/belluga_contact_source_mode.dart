enum BellugaContactSourceMode {
  own('own'),
  mirroredAccountProfile('mirrored_account_profile');

  const BellugaContactSourceMode(this.rawValue);

  final String rawValue;

  static BellugaContactSourceMode fromRaw(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return normalized == mirroredAccountProfile.rawValue
        ? mirroredAccountProfile
        : own;
  }
}
