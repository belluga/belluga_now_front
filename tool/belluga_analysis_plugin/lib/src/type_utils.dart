import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:belluga_analysis_plugin/src/path_utils.dart';

const _domainPrimitiveTypeNames = {
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

const _domainForbiddenCollectionTypeNames = {
  'Map',
  'List',
  'Set',
  'Iterable',
  'Collection',
};

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

String? sourcePathOfTypeArgument(TypeArgumentList? typeArguments) {
  final args = typeArguments?.arguments;
  if (args == null || args.isEmpty) {
    return null;
  }

  final firstArgument = args.first;
  if (firstArgument is! NamedType) {
    return null;
  }

  return sourcePathOfNamedType(firstArgument);
}

String dartTypeName(DartType? type) {
  if (type == null) {
    return '';
  }

  return normalizeTypeName(type.getDisplayString());
}

String? sourcePathOfTypeAnnotation(TypeAnnotation? type) {
  if (type is! NamedType) {
    return null;
  }

  return sourcePathOfNamedType(type);
}

String? sourcePathOfNamedType(NamedType type) {
  final element = type.element;
  if (element != null) {
    final source =
        element.firstFragment.libraryFragment?.source ??
        element.library?.firstFragment.source;
    if (source != null) {
      return normalizePath(source.fullName);
    }
  }

  return sourcePathOfDartType(type.type);
}

String? sourcePathOfDartType(DartType? type) {
  if (type == null) {
    return null;
  }

  if (type is FunctionType) {
    return sourcePathOfDartType(type.returnType);
  }

  final alias = type.alias;
  if (alias != null) {
    return sourcePathOfDartType(alias.element.aliasedType);
  }

  if (type is InterfaceType) {
    return normalizePath(type.element.library.firstFragment.source.fullName);
  }

  return null;
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

bool isRepositoryTypeName(String? typeName) {
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  return typeName.endsWith('Repository') ||
      typeName.endsWith('RepositoryContract');
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

  final typeName = topLevelTypeName(type);
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  if (type is NamedType &&
      containsForbiddenDomainPrimitiveDartType(type.type)) {
    return true;
  }

  if (typeName == 'Map') {
    return true;
  }

  if (typeName == 'List' || typeName == 'Set' || typeName == 'Iterable') {
    final args = typeArgumentListOf(type)?.arguments;
    if (args == null || args.isEmpty) {
      return true;
    }

    return args.any(containsForbiddenDomainPrimitiveType);
  }

  if (_domainPrimitiveTypeNames.contains(typeName)) {
    return true;
  }

  final args = typeArgumentListOf(type)?.arguments;
  if (args == null || args.isEmpty) {
    return false;
  }

  if (typeName == 'List' || typeName == 'Set' || typeName == 'Iterable') {
    return args.any(containsForbiddenDomainPrimitiveType);
  }

  return false;
}

bool containsForbiddenDomainValueObjectCollectionPayload(TypeAnnotation? type) {
  if (type == null || type is GenericFunctionType || type is! NamedType) {
    return false;
  }

  return _containsForbiddenDomainValueObjectCollectionPayloadType(type.type);
}

bool isAllowedDomainParameterType(TypeAnnotation? type) {
  if (type == null || type is GenericFunctionType || type is! NamedType) {
    return false;
  }

  if (_isAllowedDomainCollectionParameterType(type)) {
    return true;
  }

  final dartType = type.type;
  if (dartType is! InterfaceType) {
    return false;
  }

  if (_isValueObjectType(dartType)) {
    return !containsForbiddenDomainValueObjectCollectionPayload(type);
  }

  // Anything declared under `domain/**/value_objects/**` must actually be a
  // ValueObject subtype. Plain classes in that folder are treated as
  // workaround-shaped and are forbidden in domain signatures.
  if (_isDomainValueObjectsFolderType(dartType)) {
    return false;
  }

  return _isDomainOwnedType(dartType);
}

bool _isAllowedDomainCollectionParameterType(NamedType type) {
  final typeName = topLevelTypeName(type);
  if (typeName != 'List' && typeName != 'Set' && typeName != 'Iterable') {
    return false;
  }

  final typeArguments = type.typeArguments?.arguments;
  if (typeArguments == null || typeArguments.length != 1) {
    return false;
  }

  final elementType = typeArguments.first;
  if (elementType is! NamedType) {
    return false;
  }

  final elementDartType = elementType.type;
  if (elementDartType is! InterfaceType) {
    return false;
  }

  if (_isValueObjectType(elementDartType)) {
    return !containsForbiddenDomainValueObjectCollectionPayload(elementType);
  }

  if (_isDomainValueObjectsFolderType(elementDartType)) {
    return false;
  }

  return _isDomainOwnedType(elementDartType);
}

bool containsForbiddenDomainPrimitiveDartType(
  DartType? type, [
  Set<Element>? visitedAliasElements,
]) {
  if (type == null) {
    return false;
  }
  final visited = visitedAliasElements ?? <Element>{};

  if (type is DynamicType) {
    return true;
  }

  final typeName = normalizeTypeName(
    type.getDisplayString(withNullability: false),
  );
  if (_domainPrimitiveTypeNames.contains(typeName)) {
    return true;
  }

  final alias = type.alias;
  if (alias != null) {
    final aliasElement = alias.element;
    if (visited.add(aliasElement) &&
        containsForbiddenDomainPrimitiveDartType(
          aliasElement.aliasedType,
          visited,
        )) {
      return true;
    }
  }

  if (type is InterfaceType) {
    if (typeName == 'Map') {
      return true;
    }

    if (typeName == 'List' || typeName == 'Set' || typeName == 'Iterable') {
      if (type.typeArguments.isEmpty) {
        return true;
      }

      for (final arg in type.typeArguments) {
        if (containsForbiddenDomainPrimitiveDartType(arg, visited)) {
          return true;
        }
      }
    }
  }

  return false;
}

bool _containsForbiddenDomainValueObjectCollectionPayloadType(
  DartType? type, [
  Set<Element>? visitedAliasElements,
]) {
  if (type == null) {
    return false;
  }
  final visited = visitedAliasElements ?? <Element>{};

  final alias = type.alias;
  if (alias != null) {
    final aliasElement = alias.element;
    if (visited.add(aliasElement) &&
        _containsForbiddenDomainValueObjectCollectionPayloadType(
          aliasElement.aliasedType,
          visited,
        )) {
      return true;
    }
  }

  if (type is! InterfaceType) {
    return false;
  }

  final valueObjectSupertype = _resolveValueObjectSupertype(type);
  if (valueObjectSupertype == null ||
      valueObjectSupertype.typeArguments.isEmpty) {
    return false;
  }

  final payloadType = valueObjectSupertype.typeArguments.first;
  return _isForbiddenDomainValueObjectPayloadType(payloadType, visited);
}

bool _isForbiddenDomainValueObjectPayloadType(
  DartType type, [
  Set<Element>? visitedAliasElements,
]) {
  final visited = visitedAliasElements ?? <Element>{};

  if (type is DynamicType) {
    return false;
  }

  final alias = type.alias;
  if (alias != null) {
    final aliasElement = alias.element;
    if (visited.add(aliasElement) &&
        _isForbiddenDomainValueObjectPayloadType(
          aliasElement.aliasedType,
          visited,
        )) {
      return true;
    }
  }

  final typeName = normalizeTypeName(
    type.getDisplayString(withNullability: false),
  );
  if (_domainForbiddenCollectionTypeNames.contains(typeName)) {
    return true;
  }

  if (type is! InterfaceType) {
    return false;
  }

  final elementName = normalizeTypeName(type.element.name ?? '');
  return _domainForbiddenCollectionTypeNames.contains(elementName);
}

InterfaceType? _resolveValueObjectSupertype(InterfaceType type) {
  if (normalizeTypeName(type.element.name ?? '') == 'ValueObject') {
    return type;
  }

  for (final supertype in type.allSupertypes) {
    if (normalizeTypeName(supertype.element.name ?? '') == 'ValueObject') {
      return supertype;
    }
  }

  return null;
}

bool _isValueObjectType(InterfaceType type) {
  return _resolveValueObjectSupertype(type) != null;
}

bool _isDomainOwnedType(InterfaceType type) {
  final sourcePath = _sourcePathOf(type);
  if (sourcePath == null) {
    return false;
  }
  return isDomainFilePath(sourcePath);
}

bool _isDomainValueObjectsFolderType(InterfaceType type) {
  final sourcePath = _sourcePathOf(type);
  if (sourcePath == null) {
    return false;
  }
  return isDomainValueObjectFilePath(sourcePath);
}

String? _sourcePathOf(InterfaceType type) {
  final source =
      type.element.firstFragment.libraryFragment?.source ??
      type.element.library.firstFragment.source;
  return normalizePath(source.fullName);
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

bool containsForbiddenRepositoryRawTransportType(TypeAnnotation? type) {
  if (type == null) {
    return false;
  }

  if (type is GenericFunctionType) {
    if (containsForbiddenRepositoryRawTransportType(type.returnType)) {
      return true;
    }

    for (final parameter in type.parameters.parameters) {
      final parameterType = formalParameterType(parameter);
      if (containsForbiddenRepositoryRawTransportType(parameterType)) {
        return true;
      }
    }

    return false;
  }

  final typeName = topLevelTypeName(type);
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  if (typeName == 'dynamic') {
    return true;
  }

  final args = typeArgumentListOf(type)?.arguments;
  if (typeName == 'Map') {
    if (args == null || args.isEmpty) {
      return true;
    }

    if (args.length >= 2) {
      final keyTypeName = topLevelTypeName(args.first);
      if (keyTypeName == 'String' &&
          containsForbiddenRepositoryRawTransportType(args[1])) {
        return true;
      }
    }
  }

  if (args == null || args.isEmpty) {
    return false;
  }

  return args.any(containsForbiddenRepositoryRawTransportType);
}

bool containsRepositoryRawPayloadMapType(TypeAnnotation? type) {
  if (type == null) {
    return false;
  }

  if (type is GenericFunctionType) {
    if (containsRepositoryRawPayloadMapType(type.returnType)) {
      return true;
    }

    for (final parameter in type.parameters.parameters) {
      final parameterType = formalParameterType(parameter);
      if (containsRepositoryRawPayloadMapType(parameterType)) {
        return true;
      }
    }

    return false;
  }

  final typeName = topLevelTypeName(type);
  if (typeName == null || typeName.isEmpty) {
    return false;
  }

  if (typeName == 'dynamic') {
    return true;
  }

  final args = typeArgumentListOf(type)?.arguments;
  if (typeName == 'Map') {
    if (args == null || args.length < 2) {
      // Bare `Map` in repositories is treated as raw transport workaround.
      return true;
    }

    final keyTypeName = topLevelTypeName(args.first);
    final valueType = args[1];
    final valueTypeName = topLevelTypeName(valueType);
    if (keyTypeName == 'String') {
      if (valueTypeName == 'Object' || valueTypeName == 'dynamic') {
        return true;
      }

      if (valueTypeName == 'Map' ||
          valueTypeName == 'List' ||
          valueTypeName == 'Iterable') {
        return true;
      }

      if (containsRepositoryRawPayloadMapType(valueType)) {
        return true;
      }
    }
  }

  if (args == null || args.isEmpty) {
    return false;
  }

  return args.any(containsRepositoryRawPayloadMapType);
}

TypeAnnotation? formalParameterType(FormalParameter parameter) {
  final normalized = parameter is DefaultFormalParameter
      ? parameter.parameter
      : parameter;

  if (normalized is SimpleFormalParameter) {
    return normalized.type;
  }

  if (normalized is SuperFormalParameter) {
    return normalized.type;
  }

  if (normalized is FieldFormalParameter) {
    return normalized.type;
  }

  if (normalized is FunctionTypedFormalParameter) {
    return normalized.returnType;
  }

  return null;
}
