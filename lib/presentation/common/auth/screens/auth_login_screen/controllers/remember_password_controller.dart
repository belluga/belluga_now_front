import 'package:belluga_now/presentation/tenant/auth/login/controllers/remember_password_contract.dart';
import 'dart:async';

class RememberPasswordController implements RememberPasswordContract {
  final _controller = StreamController<bool>.broadcast();
  bool _value = false;

  @override
  Stream<bool> get stream => _controller.stream;

  @override
  bool get value => _value;

  @override
  void set(bool newValue) {
    _value = newValue;
    _controller.sink.add(_value);
  }

  @override
  void toggle() {
    _value = !_value;
    _controller.add(_value);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
