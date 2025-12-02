import 'dart:async';

import 'package:belluga_now/presentation/tenant/auth/login/controllers/remember_password_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class RememberPassword extends StatefulWidget {
  const RememberPassword({super.key}) : controller = null;

  @visibleForTesting
  const RememberPassword.withController(
    this.controller, {
    super.key,
  });

  final RememberPasswordContract? controller;

  @override
  State<RememberPassword> createState() => _RememberPasswordState();
}

class _RememberPasswordState extends State<RememberPassword> {
  RememberPasswordContract get _controller =>
      widget.controller ?? GetIt.I<RememberPasswordContract>();

  late final StreamValue<bool> _valueStream =
      StreamValue<bool>(defaultValue: _controller.value);
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _controller.stream.listen(_valueStream.addValue);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _valueStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: _valueStream,
      builder: (context, rememberPassword) {
        final value = rememberPassword;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lembrar senha',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Switch(value: value, onChanged: _controller.set),
          ],
        );
      },
    );
  }
}
