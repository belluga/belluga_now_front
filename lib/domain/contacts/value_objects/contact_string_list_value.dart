class ContactStringListValue {
  ContactStringListValue([List<String>? raw])
      : value = List<String>.unmodifiable(raw ?? const <String>[]);

  final List<String> value;
}
