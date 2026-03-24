// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ControllerRepositoryPaginationArgumentsForbiddenRule
    extends DartLintRule {
  ControllerRepositoryPaginationArgumentsForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'controller_repository_pagination_arguments_forbidden',
            problemMessage:
                'Controller must not pass pagination control arguments (page/cursor/size/limit) into repository calls.',
            correctionMessage:
                'Treatments: expose repository intents like initialize/refresh/fetchNextPage without pagination parameters.',
          ),
        );

  static const _forbiddenPaginationArgs = <String>{
    'page',
    'pageIndex',
    'pageNumber',
    'pageSize',
    'page_size',
    'perPage',
    'per_page',
    'offset',
    'limit',
    'take',
    'cursor',
    'nextCursor',
    'lastId',
    'lastKey',
    'pageToken',
    'nextPageToken',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isPresentationControllerFilePath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      final targetType = node.realTarget?.staticType;
      if (!_looksRepositoryTarget(targetType)) {
        return;
      }

      for (final argument in node.argumentList.arguments) {
        if (argument is! NamedExpression) {
          continue;
        }

        final argumentName = argument.name.label.name;
        if (!_forbiddenPaginationArgs.contains(argumentName)) {
          continue;
        }

        reporter.atNode(argument.name.label, code);
      }
    });
  }

  bool _looksRepositoryTarget(DartType? type) {
    if (type is! InterfaceType) {
      return false;
    }

    final typeName = normalizeTypeName(type.getDisplayString());
    if (isRepositoryTypeName(typeName)) {
      return true;
    }

    if (type.typeArguments.isEmpty) {
      return false;
    }

    return type.typeArguments.any(_looksRepositoryTarget);
  }
}
