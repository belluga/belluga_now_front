import 'package:belluga_now/domain/value_objects/url_required_value.dart';

class DirectionsFallbackUrlValue extends URIRequiredValue {
  DirectionsFallbackUrlValue({
    Uri? defaultValue,
    super.isRequired = true,
  }) : super(defaultValue: defaultValue ?? Uri());
}
