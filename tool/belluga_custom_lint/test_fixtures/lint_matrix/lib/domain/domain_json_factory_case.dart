class DomainJsonFactoryCase {
  const DomainJsonFactoryCase();

  // expect_lint: domain_json_factory_forbidden
  factory DomainJsonFactoryCase.fromJson(Map<String, dynamic> json) {
    return const DomainJsonFactoryCase();
  }
}
