import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/route_instance_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

typedef RouteScopedResolverErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  VoidCallback retry,
);
typedef RouteScopedResolverHook = FutureOr<void> Function(
  RouteResolverParams params,
);
typedef RouteScopedResolverResultHook<T> = FutureOr<void> Function(T model);
typedef RouteScopedResolverErrorHook = FutureOr<void> Function(
  Object error,
  RouteResolverParams params,
);

abstract class RouteScopedResolverRoute<TModel, TModule extends ModuleContract>
    extends StatelessWidget implements AutoRouteWrapper {
  const RouteScopedResolverRoute({
    super.key,
    this.onResolveStart,
    this.onResolveSuccess,
    this.onResolveError,
  });

  final RouteScopedResolverHook? onResolveStart;
  final RouteScopedResolverResultHook<TModel>? onResolveSuccess;
  final RouteScopedResolverErrorHook? onResolveError;

  @protected
  RouteResolverParams get resolverParams => const {};

  Future<TModel> resolve(
    BuildContext context,
    RouteResolverParams params,
  ) {
    final resolver = RouteResolverRegistry.instance.resolverFor<TModel>();
    if (resolver == null) {
      throw StateError(
        'No RouteModelResolver registered for $TModel. '
        'Register one or override resolve() in ${runtimeType.toString()}.',
      );
    }
    return resolver.resolve(params);
  }

  Widget buildScreen(BuildContext context, TModel model);

  Widget buildLoading(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );

  RouteScopedResolverErrorBuilder get errorBuilder =>
      (context, error, retry) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Algo deu errado'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: retry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );

  @override
  Widget wrappedRoute(BuildContext context) {
    return ModuleScope<TModule>(
      child: RouteInstanceScope(
        child: this,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RouteScopedResolverBuilder<TModel>(
      resolver: (params) => resolve(context, params),
      routeParamsBuilder: () => resolverParams,
      builder: buildScreen,
      loadingBuilder: buildLoading,
      errorBuilder: errorBuilder,
      onResolveStart: onResolveStart,
      onResolveSuccess: onResolveSuccess,
      onResolveError: onResolveError,
    );
  }
}

class _RouteScopedResolverBuilder<T> extends StatefulWidget {
  const _RouteScopedResolverBuilder({
    required this.resolver,
    required this.routeParamsBuilder,
    required this.builder,
    required this.loadingBuilder,
    required this.errorBuilder,
    this.onResolveStart,
    this.onResolveSuccess,
    this.onResolveError,
  });

  final Future<T> Function(RouteResolverParams) resolver;
  final RouteResolverParams Function() routeParamsBuilder;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext) loadingBuilder;
  final RouteScopedResolverErrorBuilder errorBuilder;
  final RouteScopedResolverHook? onResolveStart;
  final RouteScopedResolverResultHook<T>? onResolveSuccess;
  final RouteScopedResolverErrorHook? onResolveError;

  @override
  State<_RouteScopedResolverBuilder<T>> createState() =>
      _RouteScopedResolverBuilderState<T>();
}

class _RouteScopedResolverBuilderState<T>
    extends State<_RouteScopedResolverBuilder<T>> {
  late Future<T> _future;
  RouteResolverParams? _lastResolvedParams;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _RouteScopedResolverBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextParams = widget.routeParamsBuilder();
    if (!mapEquals(_lastResolvedParams, nextParams)) {
      setState(() => _resolveWithParams(nextParams));
    }
  }

  void _resolve() {
    _resolveWithParams(widget.routeParamsBuilder());
  }

  void _resolveWithParams(RouteResolverParams params) {
    _lastResolvedParams = Map<String, Object?>.from(params);
    _future = _runResolver(_lastResolvedParams!);
  }

  Future<T> _runResolver(RouteResolverParams params) async {
    await widget.onResolveStart?.call(params);
    try {
      final result = await widget.resolver(params);
      await widget.onResolveSuccess?.call(result);
      return result;
    } catch (error) {
      await widget.onResolveError?.call(error, params);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingBuilder(context);
        }

        if (snapshot.hasError) {
          return widget.errorBuilder(
            context,
            snapshot.error!,
            () => setState(_resolve),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return widget.errorBuilder(
            context,
            StateError('Resolver returned null'),
            () => setState(_resolve),
          );
        }

        return widget.builder(context, data);
      },
    );
  }
}
