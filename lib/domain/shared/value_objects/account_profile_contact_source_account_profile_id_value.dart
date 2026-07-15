import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class AccountProfileContactSourceAccountProfileIdValue extends MongoIDValue {
  AccountProfileContactSourceAccountProfileIdValue([String raw = ''])
    : super(defaultValue: '') {
    if (raw.trim().isNotEmpty) {
      parse(raw);
    }
  }
}
