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

String? topLevelTypeName(TypeAnnotation? type) {
  if (type == null) {
    return null;
  }

  return normalizeTypeName(type.toSource());
}

TypeArgumentList? typeArgumentListOf(TypeAnnotation? type) {
  if (type is NamedType) {
    return type.typeArguments;
  }

  return null;
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

bool containsDtoTypeAnnotation(TypeAnnotation? type) {
  if (type == null || type is GenericFunctionType) {
    return false;
  }

  final typeName = topLevelTypeName(type);
  if (isDtoTypeName(typeName)) {
    return true;
  }

  final args = typeArgumentListOf(type)?.arguments;
  if (args == null || args.isEmpty) {
    return false;
  }

  return args.any(containsDtoTypeAnnotation);
}

bool containsForbiddenDomainPrimitiveType(TypeAnnotation? type) {
  if (type == null || type is GenericFunctionType) {
    return false;
  }

  const primitiveTypeNames = {
    'String',
    'int',
    'double',
    'bool',
    'num',
    'DateTime',
    'Duration',
    'Uri',
    'dynamic',
  };

  final typeName = topLevelTypeName(type);
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  if (primitiveTypeNames.contains(typeName)) {
    return true;
  }

  final args = typeArgumentListOf(type)?.arguments;
  if (typeName == 'Map' && (args == null || args.isEmpty)) {
    return true;
  }

  if (args == null || args.isEmpty) {
    return false;
  }

  if (typeName == 'List' ||
      typeName == 'Set' ||
      typeName == 'Iterable' ||
      typeName == 'Map') {
    return args.any(containsForbiddenDomainPrimitiveType);
  }

  return false;
}

bool hasMeaningfulPayloadType(TypeAnnotation? type) {
  if (type == null || type is GenericFunctionType) {
    return false;
  }

  final typeName = topLevelTypeName(type);
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  if (typeName == 'void' || typeName == 'Never') {
    return false;
  }

  final args = typeArgumentListOf(type)?.arguments;
  if (typeName == 'Future' ||
      typeName == 'FutureOr' ||
      typeName == 'Stream' ||
      typeName == 'Iterable' ||
      typeName == 'List' ||
      typeName == 'Set') {
    if (args == null || args.isEmpty) {
      return false;
    }

    return args.any(hasMeaningfulPayloadType);
  }

  if (typeName == 'Map') {
    return false;
  }

  return true;
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
