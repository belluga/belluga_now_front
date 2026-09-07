import 'package:belluga_now/application/router/support/awaiting_module_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

void main() {
  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('waits for module registration before mounting its child', (
    tester,
  ) async {
    final module = _TestModule();
    GetIt.I.registerSingleton<_TestModule>(module);

    await tester.pumpWidget(
      const MaterialApp(
        home: AwaitingModuleScope<_TestModule>(child: _RegisteredChild()),
      ),
    );

    expect(find.text('registered'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('registered'), findsOneWidget);
    expect(module.initCalls, 1);
  });

  testWidgets('disposes the module after the child leaves the tree', (
    tester,
  ) async {
    final module = _TestModule();
    GetIt.I.registerSingleton<_TestModule>(module);

    await tester.pumpWidget(
      const MaterialApp(
        home: AwaitingModuleScope<_TestModule>(child: _RegisteredChild()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(module.disposeCalls, 1);
  });
}

class _RegisteredChild extends StatelessWidget {
  const _RegisteredChild();

  @override
  Widget build(BuildContext context) {
    return Text(GetIt.I.get<_RegisteredValue>().value);
  }
}

class _RegisteredValue {
  const _RegisteredValue(this.value);

  final String value;
}

class _TestModule extends ModuleContract {
  int initCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> init() async {
    initCalls++;
    await super.init();
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await super.dispose();
  }

  @override
  void registerDependencies() {
    registerLazySingleton<_RegisteredValue>(
      () => const _RegisteredValue('registered'),
    );
  }
}
