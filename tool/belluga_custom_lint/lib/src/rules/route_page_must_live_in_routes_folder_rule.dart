// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class RoutePageMustLiveInRoutesFolderRule extends DartLintRule {
  RoutePageMustLiveInRoutesFolderRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'route_page_must_live_in_routes_folder',
            problemMessage:
                'Classes annotated with @RoutePage must be declared under presentation routes folders.',
            correctionMessage:
                'Treatments: move the @RoutePage class to lib/presentation/**/routes/** and keep screen/controller files free of route declarations.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isPresentationFilePath(path) || isGeneratedFilePath(path)) {
      return;
    }

    if (isPresentationRouteFilePath(path)) {
      return;
    }

    context.registry.addClassDeclaration((node) {
      if (!_hasRoutePageAnnotation(node)) {
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
}
