import 'value_objects/pseudo_domain_value_object_like.dart';

abstract class ValueObject<T> {
  const ValueObject(this.value);

  final T value;
}

class _TagValue extends ValueObject<String> {
  const _TagValue(super.value);
}

class _TagCollectionValue extends ValueObject<List<String>> {
  const _TagCollectionValue(super.value);
}

class _DomainOwnedInput {
  const _DomainOwnedInput();
}

class DomainPrimitiveFieldCase {
  DomainPrimitiveFieldCase(this.id, this.tokens, this.valueObject);

  // expect_lint: domain_primitive_field_forbidden
  final String id;

  // expect_lint: domain_primitive_field_forbidden
  final List<int> tokens;

  final _TagValue valueObject;
  final _DomainPrimitiveConstructorCase helper =
      _DomainPrimitiveConstructorCase('raw');

  // expect_lint: domain_primitive_field_forbidden
  Set<String> get tags => {'a', 'b'};

  // expect_lint: domain_primitive_field_forbidden
  Map<String, Object?> get metadata => const {'k': 'v'};

  List<_TagValue> get valueObjects => const <_TagValue>[
        _TagValue('tag'),
      ];

  void acceptsDomain(_DomainOwnedInput input) {}

  void acceptsValueObject(_TagValue value) {}

  void acceptsValueObjectList(List<_TagValue> values) {}

  void acceptsValueObjectSet(Set<_TagValue> values) {}

  void acceptsDomainList(List<_DomainOwnedInput> values) {}

  void invalidPrimitive(
    // expect_lint: domain_primitive_field_forbidden
    String rawId,
  ) {}

  void invalidPrimitiveSet(
    // expect_lint: domain_primitive_field_forbidden
    Set<String> values,
  ) {}

  void invalidBareList(
    // expect_lint: domain_primitive_field_forbidden
    List values,
  ) {}

  void invalidCollectionPayloadValueObject(
    // expect_lint: domain_primitive_field_forbidden
    _TagCollectionValue payload,
  ) {}

  void invalidPseudoValueObjectFolderType(
    // expect_lint: domain_primitive_field_forbidden
    PseudoDomainValueObjectLike value,
  ) {}
}

class _DomainPrimitiveConstructorCase {
  _DomainPrimitiveConstructorCase(
    // expect_lint: domain_primitive_field_forbidden
    String rawId,
  );
}
