import 'package:belluga_now/domain/courses/enums/thumb_types.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class ThumbTypeValue extends ValueObject<ThumbTypes> {
  ThumbTypeValue({required super.defaultValue, super.isRequired = true});

  @override
  ThumbTypes doParse(String? parseValue) {
    return ThumbTypes.values.firstWhere(
      (type) => type.name == parseValue,
      orElse: () => throw InvalidValueException(),
    );
  }
}
