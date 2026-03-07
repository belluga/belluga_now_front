import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';

String normalizeTypeName(String raw) {
  final withoutNullability = raw.replaceAll('?', '');
  final genericIndex = withoutNullability.indexOf('<');
  final withoutGenerics = genericIndex == -1
      ? withoutNullability
      : withoutNullability.substring(0, genericIndex);

  final dotIndex = withoutGenerics.lastIndexOf('.');
  if (dotIndex == -1) {
    return withoutGenerics;
  }

  return withoutGenerics.substring(dotIndex + 1);
}

String? firstTypeArgumentName(TypeArgumentList? typeArguments) {
  final args = typeArguments?.arguments;
  if (args == null || args.isEmpty) {
    return null;
  }

  return normalizeTypeName(args.first.toSource());
}

String dartTypeName(DartType? type) {
  if (type == null) {
    return '';
  }

  return normalizeTypeName(type.getDisplayString());
}

bool isControllerTypeName(String? typeName) {
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  return typeName.endsWith('Controller') ||
      typeName.endsWith('ControllerContract');
}

bool isDataSourceTypeName(String? typeName) {
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  final normalized = typeName.toLowerCase();

  return normalized.contains('repository') ||
      normalized.contains('service') ||
      normalized.contains('dao') ||
      normalized.contains('datasource') ||
      normalized.contains('backend') ||
      normalized.contains('dto');
}

bool isDtoTypeName(String? typeName) {
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  return typeName.endsWith('Dto') || typeName.endsWith('DTO');
}

bool isUiControllerTypeName(String? typeName) {
  const blockedUiControllers = {
    'TextEditingController',
    'ScrollController',
    'AnimationController',
    'PageController',
    'TabController',
    'TransformationController',
  };

  return blockedUiControllers.contains(typeName);
}
