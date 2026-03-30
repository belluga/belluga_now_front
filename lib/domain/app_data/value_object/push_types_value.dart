import 'package:value_object_pattern/value_object.dart';

class PushTypesValue extends ValueObject<List<String>> {
  PushTypesValue([Iterable<String>? rawTypes])
      : super(defaultValue: const <String>[], isRequired: false) {
    parse(rawTypes?.join('\n'));
  }

  @override
  List<String> doParse(dynamic parseValue) {
    if (parseValue is Iterable) {
      return List<String>.unmodifiable(
        _sanitize(parseValue.map((item) => item.toString())),
      );
    }

    return defaultValue;
  }

  static List<String> _sanitize(Iterable<String>? rawTypes) {
    if (rawTypes == null) {
      return const <String>[];
    }

    final ordered = <String>[];
    final seen = <String>{};
    for (final raw in rawTypes) {
      final normalized = raw.trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      ordered.add(normalized);
    }
    return ordered;
  }

  bool get isEmpty => value.isEmpty;

  String join(String separator) => value.join(separator);
}
