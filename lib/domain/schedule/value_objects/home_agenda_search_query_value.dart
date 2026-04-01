import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class HomeAgendaSearchQueryValue extends GenericStringValue {
  HomeAgendaSearchQueryValue({
    super.defaultValue = '',
    super.isRequired = true,
  });
}
