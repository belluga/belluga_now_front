import 'dart:typed_data';

import 'package:value_object_pattern/value_object.dart';

class UserProfileMediaBytesValue extends ValueObject<Uint8List> {
  UserProfileMediaBytesValue({
    Uint8List? defaultValue,
  }) : super(
          defaultValue: defaultValue ?? Uint8List(0),
          isRequired: true,
        );

  @override
  Uint8List doParse(String? parseValue) => Uint8List.fromList(
        (parseValue ?? '').codeUnits,
      );
}
