enum FormValidationTargetKind {
  field,
  group,
  global,
}

class FormValidationBinding {
  const FormValidationBinding._({
    required this.targetId,
    required this.targetKind,
    required List<_ValidationKeyMatcher> matchers,
  }) : _matchers = matchers;

  final String targetId;
  final FormValidationTargetKind targetKind;
  final List<_ValidationKeyMatcher> _matchers;

  bool matches(String normalizedKey) {
    for (final matcher in _matchers) {
      if (matcher.matches(normalizedKey)) {
        return true;
      }
    }
    return false;
  }
}

FormValidationBinding field(
  String backendKey, {
  String? targetId,
}) {
  return FormValidationBinding._(
    targetId: targetId ?? backendKey.trim(),
    targetKind: FormValidationTargetKind.field,
    matchers: <_ValidationKeyMatcher>[
      _ValidationKeyMatcher.exact(backendKey),
    ],
  );
}

FormValidationBinding fieldAny(
  List<String> backendKeys, {
  required String targetId,
}) {
  return FormValidationBinding._(
    targetId: targetId,
    targetKind: FormValidationTargetKind.field,
    matchers:
        backendKeys.map(_ValidationKeyMatcher.exact).toList(growable: false),
  );
}

FormValidationBinding fieldPattern(
  String pattern, {
  required String targetId,
}) {
  return FormValidationBinding._(
    targetId: targetId,
    targetKind: FormValidationTargetKind.field,
    matchers: <_ValidationKeyMatcher>[
      _ValidationKeyMatcher.glob(pattern),
    ],
  );
}

FormValidationBinding group(
  String backendKey, {
  required String targetId,
}) {
  return FormValidationBinding._(
    targetId: targetId,
    targetKind: FormValidationTargetKind.group,
    matchers: <_ValidationKeyMatcher>[
      _ValidationKeyMatcher.exact(backendKey),
    ],
  );
}

FormValidationBinding groupAny(
  List<String> backendKeys, {
  required String targetId,
}) {
  return FormValidationBinding._(
    targetId: targetId,
    targetKind: FormValidationTargetKind.group,
    matchers:
        backendKeys.map(_ValidationKeyMatcher.exact).toList(growable: false),
  );
}

FormValidationBinding groupPattern(
  String pattern, {
  required String targetId,
}) {
  return FormValidationBinding._(
    targetId: targetId,
    targetKind: FormValidationTargetKind.group,
    matchers: <_ValidationKeyMatcher>[
      _ValidationKeyMatcher.glob(pattern),
    ],
  );
}

FormValidationBinding global(
  String backendKey, {
  String targetId = 'global',
}) {
  return FormValidationBinding._(
    targetId: targetId,
    targetKind: FormValidationTargetKind.global,
    matchers: <_ValidationKeyMatcher>[
      _ValidationKeyMatcher.exact(backendKey),
    ],
  );
}

FormValidationBinding globalAny(
  List<String> backendKeys, {
  String targetId = 'global',
}) {
  return FormValidationBinding._(
    targetId: targetId,
    targetKind: FormValidationTargetKind.global,
    matchers:
        backendKeys.map(_ValidationKeyMatcher.exact).toList(growable: false),
  );
}

FormValidationBinding globalPattern(
  String pattern, {
  String targetId = 'global',
}) {
  return FormValidationBinding._(
    targetId: targetId,
    targetKind: FormValidationTargetKind.global,
    matchers: <_ValidationKeyMatcher>[
      _ValidationKeyMatcher.glob(pattern),
    ],
  );
}

class _ValidationKeyMatcher {
  _ValidationKeyMatcher._({
    required bool Function(String normalizedKey) matcher,
  }) : _matcher = matcher;

  final bool Function(String normalizedKey) _matcher;

  factory _ValidationKeyMatcher.exact(String backendKey) {
    final expected = normalizeValidationKey(backendKey);
    return _ValidationKeyMatcher._(
      matcher: (normalizedKey) => normalizedKey == expected,
    );
  }

  factory _ValidationKeyMatcher.glob(String pattern) {
    final normalizedPattern = normalizeValidationKey(pattern);
    final expression = _globToRegExp(normalizedPattern);
    return _ValidationKeyMatcher._(
      matcher: (normalizedKey) => expression.hasMatch(normalizedKey),
    );
  }

  bool matches(String normalizedKey) => _matcher(normalizedKey);

  static RegExp _globToRegExp(String pattern) {
    final segments = pattern
        .split('.')
        .where((segment) => segment.isNotEmpty)
        .map((segment) => segment == '*' ? '[^.]+' : RegExp.escape(segment))
        .join(r'\.');
    return RegExp('^$segments\$');
  }
}

String normalizeValidationKey(String rawKey) {
  final trimmed = rawKey.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  var normalized = trimmed.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]'),
    (match) => '.${match.group(1)}',
  );
  normalized = normalized.replaceAll(RegExp(r'\.{2,}'), '.');
  if (normalized.startsWith('.')) {
    normalized = normalized.substring(1);
  }
  if (normalized.endsWith('.')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}
