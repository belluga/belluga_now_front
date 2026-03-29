import 'package:value_object_pattern/value_object.dart';

class ExperienceStringListValue extends ValueObject<List<String>> {
  ExperienceStringListValue([List<String>? raw])
      : super(defaultValue: const <String>[], isRequired: false) {
    parse(raw?.join('\n'));
  }

  @override
  List<String> doParse(dynamic parseValue) {
    if (parseValue is Iterable) {
      return List<String>.unmodifiable(
        parseValue.map((item) => item.toString()),
      );
    }

    return defaultValue;
  }
}
