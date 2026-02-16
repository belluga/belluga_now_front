import 'package:belluga_now/presentation/tenant/auth/login/controllers/remember_password_contract.dart';
import 'package:stream_value/core/stream_value.dart';

class RememberPasswordController implements RememberPasswordContract {
  final StreamValue<bool> _streamValue = StreamValue<bool>(defaultValue: false);

  @override
  Stream<bool> get stream => _streamValue.stream;

  @override
  bool get value => _streamValue.value;

  @override
  void set(bool newValue) {
    _streamValue.addValue(newValue);
  }

  @override
  void toggle() {
    _streamValue.addValue(!value);
  }

  @override
  void dispose() {
    _streamValue.dispose();
  }
}
