import 'package:value_object_pattern/value_object.dart';

class RouteReferencePointPolicyValue extends ValueObject<bool?> {
  RouteReferencePointPolicyValue([bool? raw])
      : super(defaultValue: null, isRequired: false) {
    set(raw);
  }

  RouteReferencePointPolicyValue.prompt() : this(null);

  @override
  bool? doParse(dynamic parseValue) {
    if (parseValue is bool) {
      return parseValue;
    }
    return null;
  }

  bool get shouldPrompt => value == null;
  bool get usesReferencePoint => value == true;
  bool get usesLiveLocation => value == false;
}
