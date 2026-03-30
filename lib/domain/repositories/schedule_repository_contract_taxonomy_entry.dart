import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_text_value.dart';

class ScheduleRepositoryContractTaxonomyEntry {
  ScheduleRepositoryContractTaxonomyEntry({
    required this.type,
    required this.term,
  });

  final ScheduleRepositoryContractTextValue type;
  final ScheduleRepositoryContractTextValue term;
}
