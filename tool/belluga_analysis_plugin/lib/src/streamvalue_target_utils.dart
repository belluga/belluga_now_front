import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import 'type_utils.dart';

bool isStreamValueExpression(Expression? expression) {
  return dartTypeName(expression?.staticType) == 'StreamValue';
}

bool isExternalStreamTarget(Expression target) {
  if (target is PropertyAccess) {
    final owner = target.target;
    return owner != null && owner is! ThisExpression;
  }

  if (target is PrefixedIdentifier) {
    return true;
  }

  return false;
}

PropertyAccessorElement? resolveStreamValueAccessor(Expression target) {
  if (target is SimpleIdentifier) {
    final element = target.element;
    return element is PropertyAccessorElement ? element : null;
  }

  if (target is PropertyAccess) {
    final element = target.propertyName.element;
    return element is PropertyAccessorElement ? element : null;
  }

  if (target is PrefixedIdentifier) {
    final element = target.identifier.element;
    return element is PropertyAccessorElement ? element : null;
  }

  return null;
}

bool isExplicitStreamGetter(PropertyAccessorElement accessor) {
  return !accessor.isSynthetic &&
      dartTypeName(accessor.returnType) == 'StreamValue';
}

bool isDelegatedStreamTarget(Expression target) {
  if (!isStreamValueExpression(target)) {
    return false;
  }

  if (isExternalStreamTarget(target)) {
    return true;
  }

  final accessor = resolveStreamValueAccessor(target);
  if (accessor == null) {
    return false;
  }

  return isExplicitStreamGetter(accessor);
}
