import 'package:analyzer/dart/ast/ast.dart';

bool _isGetItTargetSource(String? source) {
  return source == 'GetIt.I' || source == 'GetIt.instance';
}

bool isGetItMethodInvocation(MethodInvocation node) {
  if (node.methodName.name != 'get') {
    return false;
  }

  return _isGetItTargetSource(node.target?.toSource());
}

bool isGetItCallableInvocation(FunctionExpressionInvocation node) {
  return _isGetItTargetSource(node.function.toSource());
}

const _getItRegistrationMethodNames = {
  'registerFactory',
  'registerFactoryAsync',
  'registerFactoryParam',
  'registerLazySingleton',
  'registerLazySingletonAsync',
  'registerSingleton',
  'registerSingletonAsync',
  'registerSingletonWithDependencies',
};

bool isGetItRegistrationMethodInvocation(MethodInvocation node) {
  if (!_isGetItTargetSource(node.target?.toSource())) {
    return false;
  }

  return _getItRegistrationMethodNames.contains(node.methodName.name);
}
