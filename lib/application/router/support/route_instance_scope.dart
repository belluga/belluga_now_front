import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'route_instance_store.dart';

class RouteInstanceScope extends StatefulWidget {
  const RouteInstanceScope({
    super.key,
    required this.child,
    this.store,
    this.disposeStore,
  });

  final Widget child;
  final RouteInstanceStore? store;
  final bool? disposeStore;

  static RouteInstanceStore? maybeStoreOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_RouteInstanceScopeInherited>()
        ?.store;
  }

  static RouteInstanceStore? maybeReadStoreOf(BuildContext context) {
    final inherited = context
        .getElementForInheritedWidgetOfExactType<_RouteInstanceScopeInherited>()
        ?.widget;
    return inherited is _RouteInstanceScopeInherited ? inherited.store : null;
  }

  static RouteInstanceStore storeOf(BuildContext context) {
    final store = maybeStoreOf(context);
    if (store == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('RouteInstanceScope was not found.'),
        ErrorDescription(
          'Stackable detail routes must be built through RouteScopedResolverRoute '
          'or wrapped by RouteInstanceScope in tests.',
        ),
      ]);
    }
    return store;
  }

  static RouteInstanceStore readStoreOf(BuildContext context) {
    final store = maybeReadStoreOf(context);
    if (store == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('RouteInstanceScope was not found.'),
        ErrorDescription(
          'Stackable detail routes must be built through RouteScopedResolverRoute '
          'or wrapped by RouteInstanceScope in tests.',
        ),
      ]);
    }
    return store;
  }

  static T get<T extends Object>(BuildContext context) {
    final store = maybeStoreOf(context);
    if (store != null) {
      return store.get<T>();
    }

    return GetIt.I.get<T>();
  }

  static T read<T extends Object>(BuildContext context) {
    final store = maybeReadStoreOf(context);
    if (store != null) {
      return store.get<T>();
    }

    return GetIt.I.get<T>();
  }

  @override
  State<RouteInstanceScope> createState() => _RouteInstanceScopeState();
}

class _RouteInstanceScopeState extends State<RouteInstanceScope> {
  late RouteInstanceStore _store;
  late bool _ownsStore;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? RouteInstanceStore();
    _ownsStore = widget.disposeStore ?? widget.store == null;
  }

  @override
  void didUpdateWidget(RouteInstanceScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStore = widget.store;
    if (nextStore == null || identical(nextStore, _store)) {
      _ownsStore = widget.disposeStore ?? nextStore == null;
      return;
    }

    if (_ownsStore) {
      _store.dispose();
    }
    _store = nextStore;
    _ownsStore = widget.disposeStore ?? false;
  }

  @override
  void dispose() {
    if (_ownsStore) {
      _store.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RouteInstanceScopeInherited(
      store: _store,
      child: widget.child,
    );
  }
}

class _RouteInstanceScopeInherited extends InheritedWidget {
  const _RouteInstanceScopeInherited({
    required this.store,
    required super.child,
  });

  final RouteInstanceStore store;

  @override
  bool updateShouldNotify(_RouteInstanceScopeInherited oldWidget) {
    return !identical(store, oldWidget.store);
  }
}

Future<T?> showRouteScopedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool? requestFocus,
}) {
  final store = RouteInstanceScope.maybeStoreOf(context);
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
    requestFocus: requestFocus,
    builder: (dialogContext) => _wrapWithRouteStore(
      store: store,
      builder: builder,
      context: dialogContext,
    ),
  );
}

Future<T?> showRouteScopedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
}) {
  final store = RouteInstanceScope.maybeStoreOf(context);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: backgroundColor,
    barrierLabel: barrierLabel,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    sheetAnimationStyle: sheetAnimationStyle,
    requestFocus: requestFocus,
    builder: (sheetContext) => _wrapWithRouteStore(
      store: store,
      builder: builder,
      context: sheetContext,
    ),
  );
}

Widget _wrapWithRouteStore({
  required RouteInstanceStore? store,
  required WidgetBuilder builder,
  required BuildContext context,
}) {
  if (store == null) {
    return builder(context);
  }

  return RouteInstanceScope(
    store: store,
    disposeStore: false,
    child: Builder(builder: builder),
  );
}
