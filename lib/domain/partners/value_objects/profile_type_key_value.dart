class ProfileTypeKeyValue {
  const ProfileTypeKeyValue(String raw) : value = raw;

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileTypeKeyValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
