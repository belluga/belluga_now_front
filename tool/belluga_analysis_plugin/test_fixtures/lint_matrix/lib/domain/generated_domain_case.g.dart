class GeneratedDomainCase {
  GeneratedDomainCase(this.value);

  factory GeneratedDomainCase.fromJson(Map<String, dynamic> json) {
    return GeneratedDomainCase(json['value'] as String? ?? '');
  }

  final String value;
}

class GeneratedDomainExtraCase {}
