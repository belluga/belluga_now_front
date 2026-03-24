import 'package:belluga_now/domain/value_objects/url_required_value.dart';

class RideShareUriValue extends URIRequiredValue {
  RideShareUriValue({
    Uri? defaultValue,
    super.isRequired = true,
  }) : super(defaultValue: defaultValue ?? Uri());
}
