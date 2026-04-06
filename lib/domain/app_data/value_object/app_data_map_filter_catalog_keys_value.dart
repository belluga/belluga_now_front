import 'package:value_object_pattern/value_object.dart';

class AppDataMapFilterCatalogKeysValue extends ValueObject<List<String>> {
  AppDataMapFilterCatalogKeysValue([Iterable<String>? rawKeys])
      : super(defaultValue: const <String>[], isRequired: false) {
    parse(rawKeys?.join('\n'));
  }

  @override
  List<String> doParse(dynamic parseValue) {
    if (parseValue is Iterable) {
      return List<String>.unmodifiable(
        _sanitize(parseValue.map((item) => item.toString())),
      );
    }

    if (parseValue is String) {
      return List<String>.unmodifiable(
        _sanitize(parseValue.split(RegExp(r'[\n,]+'))),
      );
    }

    return defaultValue;
  }

  static List<String> _sanitize(Iterable<String>? rawKeys) {
    if (rawKeys == null) {
      return const <String>[];
    }

    final ordered = <String>[];
    final seen = <String>{};
    for (final raw in rawKeys) {
      final normalized = raw.trim().toLowerCase();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      ordered.add(normalized);
    }
    return ordered;
  }

  bool get isEmpty => value.isEmpty;

  int get length => value.length;

  List<String> toList({bool growable = false}) =>
      List<String>.from(value, growable: growable);
}
