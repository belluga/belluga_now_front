import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';

import 'getit_utils.dart';
import 'type_utils.dart';

const _moduleWrapperRegistrationMethodNames = {
  'registerFactory',
  'registerFactoryAsync',
  'registerFactoryParam',
  'registerLazySingleton',
  'registerLazySingletonAsync',
  'registerSingleton',
  'registerSingletonAsync',
  'registerSingletonWithDependencies',
  '_registerIfAbsent',
  '_registerLazySingletonIfAbsent',
};

const disallowedRepositoryLifecycleMethodNames = {
  'registerFactory',
  'registerFactoryAsync',
  'registerFactoryParam',
};

bool isRepositoryRegistrationInvocation(MethodInvocation node) {
  if (!_isRegistrationMethodInvocation(node)) {
    return false;
  }

  return _registeredTypeLooksLikeRepository(node);
}

bool isRepositoryFactoryLifecycleInvocation(MethodInvocation node) {
  if (!disallowedRepositoryLifecycleMethodNames
      .contains(node.methodName.name)) {
    return false;
  }

  if (!_isRegistrationMethodInvocation(node)) {
    return false;
  }

  return _registeredTypeLooksLikeRepository(node);
}

bool _isRegistrationMethodInvocation(MethodInvocation node) {
  if (isGetItRegistrationMethodInvocation(node)) {
    return true;
  }

  return node.target == null &&
      _moduleWrapperRegistrationMethodNames.contains(node.methodName.name);
}

bool _registeredTypeLooksLikeRepository(MethodInvocation node) {
  final typeName = firstTypeArgumentName(node.typeArguments);
  if (isRepositoryTypeName(typeName)) {
    return true;
  }

  final args = node.argumentList.arguments;
  if (args.isEmpty) {
    return false;
  }

  final firstArgument = args.first;
  if (_expressionContainsRepositoryConstructor(firstArgument)) {
    return true;
  }

  return _dartTypeContainsRepository(firstArgument.staticType);
}

bool _expressionContainsRepositoryConstructor(Expression expression) {
  if (expression is FunctionExpression) {
    final body = expression.body;
    if (body is ExpressionFunctionBody) {
      final bodyExpression = body.expression;
      if (bodyExpression is InstanceCreationExpression) {
        final createdType =
            normalizeTypeName(bodyExpression.constructorName.type.toSource());
        return isRepositoryTypeName(createdType);
      }
      if (bodyExpression is MethodInvocation) {
        final methodName = bodyExpression.methodName.name;
        if (isRepositoryTypeName(methodName)) {
          return true;
        }
      }
    }

    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is! ReturnStatement) {
          continue;
        }
        final returned = statement.expression;
        if (returned is InstanceCreationExpression) {
          final createdType =
              normalizeTypeName(returned.constructorName.type.toSource());
          if (isRepositoryTypeName(createdType)) {
            return true;
          }
        }
      }
    }
  }

  return false;
}

bool _dartTypeContainsRepository(DartType? type) {
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

  return type.typeArguments.any(_dartTypeContainsRepository);
}
