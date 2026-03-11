class _ValueObjectLike {
  const _ValueObjectLike();
}

class DomainPrimitiveFieldCase {
  DomainPrimitiveFieldCase(this.id, this.tokens, this.valueObject);

  // expect_lint: domain_primitive_field_forbidden
  final String id;

  // expect_lint: domain_primitive_field_forbidden
  final List<int> tokens;

  final _ValueObjectLike valueObject;
}
