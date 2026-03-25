// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class RouteRequiredNonUrlArgsForbiddenRule extends DartLintRule {
  RouteRequiredNonUrlArgsForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'route_required_non_url_args_forbidden',
            problemMessage:
                'Route pages cannot require constructor args that are not URL-bound (@PathParam/@QueryParam).',
            correctionMessage:
                'Treatments: make route args optional for internal-only flows with deterministic fallback, or move required identifiers to URL path/query with resolver hydration.',
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

      final constructor = _selectPrimaryConstructor(node);
      if (constructor == null) {
        return;
      }

      for (final parameter in constructor.parameters.parameters) {
        if (!_isRequiredRouteArg(parameter)) {
          continue;
        }
        if (_isUrlBoundParam(parameter)) {
          continue;
        }
        if (_isOptionalUiKey(parameter)) {
          continue;
        }
        reporter.atNode(_reportNode(parameter), code);
      }
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

  ConstructorDeclaration? _selectPrimaryConstructor(ClassDeclaration node) {
    ConstructorDeclaration? unnamed;
    for (final member in node.members) {
      if (member is! ConstructorDeclaration) {
        continue;
      }
      if (member.name == null) {
        unnamed = member;
        break;
      }
    }
    return unnamed;
  }

  bool _isRequiredRouteArg(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return parameter.requiredKeyword != null;
    }

    return parameter.isRequiredPositional;
  }

  bool _isUrlBoundParam(FormalParameter parameter) {
    bool hasUrlAnnotation(NodeList<Annotation> metadata) {
      for (final annotation in metadata) {
        final name = normalizeTypeName(annotation.name.toSource());
        if (name == 'PathParam' || name == 'QueryParam') {
          return true;
        }
      }
      return false;
    }

    if (hasUrlAnnotation(parameter.metadata)) {
      return true;
    }
    if (parameter is DefaultFormalParameter) {
      if (hasUrlAnnotation(parameter.metadata)) {
        return true;
      }
      return _isUrlBoundParam(parameter.parameter);
    }
    return false;
  }

  bool _isOptionalUiKey(FormalParameter parameter) {
    final normalized =
        parameter is DefaultFormalParameter ? parameter.parameter : parameter;
    final typeName = topLevelTypeName(formalParameterType(normalized));
    final name = _parameterName(normalized);
    return name == 'key' && typeName == 'Key';
  }

  AstNode _reportNode(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return _reportNode(parameter.parameter);
    }
    return parameter;
  }

  String? _parameterName(FormalParameter parameter) {
    if (parameter is SimpleFormalParameter) {
      return parameter.name?.lexeme;
    }
    if (parameter is FieldFormalParameter) {
      return parameter.name.lexeme;
    }
    if (parameter is SuperFormalParameter) {
      return parameter.name.lexeme;
    }
    return null;
  }
}
