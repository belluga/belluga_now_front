import 'package:unifast_portal/domain/value_objects/url_required_value.dart';

class ExternalCoursePlatformUriValue extends URIRequiredValue {
  ExternalCoursePlatformUriValue({
    required super.defaultValue,
    super.isRequired = true,
  });
}
