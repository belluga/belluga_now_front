import 'package:belluga_now/application/router/support/route_instance_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets('keeps one instance per route scope and isolates nested scopes',
      (tester) async {
    var nextId = 0;
    final created = <_ProbeController>[];
    GetIt.I.registerFactory<_ProbeController>(() {
      final controller = _ProbeController(++nextId);
      created.add(controller);
      return controller;
    });

    late _ProbeController parentFirst;
    late _ProbeController parentSecond;
    late _ProbeController child;

    await tester.pumpWidget(
      MaterialApp(
        home: RouteInstanceScope(
          child: Builder(
            builder: (context) {
              parentFirst = RouteInstanceScope.get<_ProbeController>(context);
              parentSecond = RouteInstanceScope.get<_ProbeController>(context);
              return RouteInstanceScope(
                child: Builder(
                  builder: (context) {
                    child = RouteInstanceScope.get<_ProbeController>(context);
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(created, hasLength(2));
    expect(identical(parentFirst, parentSecond), isTrue);
    expect(identical(parentFirst, child), isFalse);
    expect(parentFirst.id, 1);
    expect(child.id, 2);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(parentFirst.disposed, isTrue);
    expect(child.disposed, isTrue);
  });

  testWidgets('re-exposes the route scope inside dialogs and bottom sheets',
      (tester) async {
    var nextId = 0;
    GetIt.I.registerFactory<_ProbeController>(
      () => _ProbeController(++nextId),
    );

    _ProbeController? routeController;
    _ProbeController? dialogController;
    _ProbeController? sheetController;

    await tester.pumpWidget(
      MaterialApp(
        home: RouteInstanceScope(
          child: Builder(
            builder: (context) {
              routeController =
                  RouteInstanceScope.get<_ProbeController>(context);
              return Column(
                children: [
                  TextButton(
                    key: const Key('openRouteScopedDialog'),
                    onPressed: () {
                      showRouteScopedDialog<void>(
                        context: context,
                        builder: (dialogContext) {
                          dialogController =
                              RouteInstanceScope.get<_ProbeController>(
                            dialogContext,
                          );
                          return AlertDialog(
                            content: const Text('Dialog'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Fechar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Dialog'),
                  ),
                  TextButton(
                    key: const Key('openRouteScopedSheet'),
                    onPressed: () {
                      showRouteScopedModalBottomSheet<void>(
                        context: context,
                        builder: (sheetContext) {
                          sheetController =
                              RouteInstanceScope.get<_ProbeController>(
                            sheetContext,
                          );
                          return TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Fechar sheet'),
                          );
                        },
                      );
                    },
                    child: const Text('Sheet'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('openRouteScopedDialog')));
    await tester.pumpAndSettle();

    expect(identical(routeController, dialogController), isTrue);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openRouteScopedSheet')));
    await tester.pumpAndSettle();

    expect(identical(routeController, sheetController), isTrue);
  });
}

class _ProbeController implements Disposable {
  _ProbeController(this.id);

  final int id;
  bool disposed = false;

  @override
  void onDispose() {
    disposed = true;
  }
}
