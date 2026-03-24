class ContactAvatarBytesValue {
  ContactAvatarBytesValue([List<int>? raw])
      : value = raw == null ? null : List<int>.unmodifiable(raw);

  final List<int>? value;
}
