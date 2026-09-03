import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

/// Mounts a module's subtree only after its asynchronous registrations finish.
///
/// The package `ModuleScope` starts initialization from `initState`, but it
/// does not wait before building its child. That can expose a transient
/// missing-registration window for a shell with deep-linked child routes. The
/// shell uses this scope as the lifecycle barrier; child scopes can continue
/// to participate in the module reference count below it.
class AwaitingModuleScope<T extends ModuleContract> extends StatefulWidget {
  const AwaitingModuleScope({super.key, required this.child});

  final Widget child;

  @override
  State<AwaitingModuleScope<T>> createState() => _AwaitingModuleScopeState<T>();
}

class _AwaitingModuleScopeState<T extends ModuleContract>
    extends State<AwaitingModuleScope<T>> {
  late final T _module;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _module = GetIt.I.get<T>();
    _initialization = _module.init();
  }

  @override
  void dispose() {
    unawaited(_module.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Não foi possível carregar a área.')),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.child;
      },
    );
  }
}
