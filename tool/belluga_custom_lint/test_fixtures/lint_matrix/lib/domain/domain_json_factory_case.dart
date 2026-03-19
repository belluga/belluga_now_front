class DomainJsonFactoryCase {
  const DomainJsonFactoryCase();

  // expect_lint: domain_json_factory_forbidden
  factory DomainJsonFactoryCase.fromJson(
    // expect_lint: domain_primitive_field_forbidden
    Map<String, dynamic> json,
  ) {
    return const DomainJsonFactoryCase();
  }
}
