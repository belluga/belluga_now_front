// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class RoutePathParamRequiresResolverRouteRule extends DartLintRule {
  RoutePathParamRequiresResolverRouteRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'route_path_param_requires_resolver_route',
            problemMessage:
                'Route pages with @PathParam must use ResolverRoute model hydration.',
            correctionMessage:
                'Treatments: replace Stateless/Stateful route wrappers with ResolverRoute and define resolverParams/buildScreen with hydrated model.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!path.contains('/lib/presentation/') || !path.contains('/routes/')) {
      return;
    }

    context.registry.addClassDeclaration((node) {
      if (!_hasRoutePageAnnotation(node)) {
        return;
      }
      if (!_hasPathParamConstructorParameter(node)) {
        return;
      }
      if (_extendsResolverRoute(node)) {
        return;
      }

      reporter.atNode(node, code);
    });
  }

  bool _hasRoutePageAnnotation(ClassDeclaration node) {
    for (final annotation in node.metadata) {
      final annotationName = normalizeTypeName(annotation.name.toSource());
      if (annotationName == 'RoutePage') {
        return true;
      }
    }
    return false;
  }

  bool _hasPathParamConstructorParameter(ClassDeclaration node) {
    for (final member in node.members) {
      if (member is! ConstructorDeclaration) {
        continue;
      }
      for (final parameter in member.parameters.parameters) {
        if (_parameterHasPathParamAnnotation(parameter)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _parameterHasPathParamAnnotation(FormalParameter parameter) {
    if (_hasPathParamAnnotation(parameter.metadata)) {
      return true;
    }

    if (parameter is DefaultFormalParameter) {
      if (_hasPathParamAnnotation(parameter.metadata)) {
        return true;
      }
      return _parameterHasPathParamAnnotation(parameter.parameter);
    }

    return false;
  }

  bool _hasPathParamAnnotation(NodeList<Annotation> metadata) {
    for (final annotation in metadata) {
      final annotationName = normalizeTypeName(annotation.name.toSource());
      if (annotationName == 'PathParam') {
        return true;
      }
    }
    return false;
  }

  bool _extendsResolverRoute(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) {
      return false;
    }

    final superTypeName =
        normalizeTypeName(extendsClause.superclass.toSource());
    return superTypeName == 'ResolverRoute';
  }
}
