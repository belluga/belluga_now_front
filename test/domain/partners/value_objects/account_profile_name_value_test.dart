import 'dart:io';

import 'package:belluga_now/domain/partners/value_objects/account_profile_name_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';

void main() {
  final laravelRoot = Directory('../laravel-app');

  test('matches relevant Laravel Account Profile CRUD bounds', () {
    final requestContracts = <String, String>{
      '../laravel-app/app/Http/Api/v1/Requests/AccountOnboardingStoreRequest.php':
          "'name' => \$this->publicVisibleNameRules(required: true)",
      '../laravel-app/app/Http/Api/v1/Requests/AccountProfileUpdateRequest.php':
          "'display_name' => \$this->publicVisibleNameRules(required: false)",
    };
    final minimumPattern = RegExp(
      r'MIN_VISIBLE_PUBLIC_NAME_LENGTH\s*=\s*(\d+)',
    );
    final constraintsFile = File(
      '../laravel-app/app/Support/Validation/InputConstraints.php',
    );
    expect(constraintsFile.existsSync(), isTrue);
    final maximumMatch = RegExp(
      r'NAME_MAX\s*=\s*(\d+)',
    ).firstMatch(constraintsFile.readAsStringSync());
    expect(maximumMatch, isNotNull);
    expect(
      int.parse(maximumMatch!.group(1)!),
      AccountProfileNameValue.maximumLength,
    );

    for (final entry in requestContracts.entries) {
      final requestPath = entry.key;
      final requestFile = File(requestPath);
      expect(requestFile.existsSync(), isTrue, reason: requestPath);
      final requestSource = requestFile.readAsStringSync();
      final match = minimumPattern.firstMatch(requestSource);
      expect(match, isNotNull, reason: requestPath);
      final helperMatch = RegExp(
        r'private function publicVisibleNameRules\([\s\S]*?^    \}',
        multiLine: true,
      ).firstMatch(requestSource);
      expect(helperMatch, isNotNull, reason: requestPath);
      final helperSource = helperMatch!.group(0)!;
      expect(
        int.parse(match!.group(1)!),
        AccountProfileNameValue.minimumLength,
        reason:
            '$requestPath and AccountProfileNameValue must keep the same minimum.',
      );
      expect(
        helperSource,
        contains("'max:'.InputConstraints::NAME_MAX"),
        reason:
            '$requestPath publicVisibleNameRules must use the shared Laravel name maximum.',
      );
      expect(
        requestSource,
        contains(entry.value),
        reason: '$requestPath must bind its Account Profile name field.',
      );
      expect(helperSource, contains(r'$trimmed = trim($value)'));
      expect(
        helperSource,
        contains(r'mb_strlen($trimmed) < self::MIN_VISIBLE_PUBLIC_NAME_LENGTH'),
      );
    }
  }, skip: laravelRoot.existsSync() ? false : 'Laravel sibling unavailable');

  test('accepts three trimmed Unicode code points', () {
    final value = AccountProfileNameValue()..parse('  A😀B  ');

    expect(value.value, 'A😀B');
  });

  test('accepts the production name AGLA', () {
    final value = AccountProfileNameValue()..parse('AGLA');

    expect(value.value, 'AGLA');
  });

  test('rejects two ASCII characters after trimming', () {
    expect(
      () => AccountProfileNameValue()..parse('  An  '),
      throwsA(isA<TooShortValueException<dynamic>>()),
    );
  });

  test('counts supplementary Unicode as one code point', () {
    expect(
      () => AccountProfileNameValue()..parse('A😀'),
      throwsA(isA<TooShortValueException<dynamic>>()),
    );
  });

  test('rejects empty content after trimming', () {
    expect(
      () => AccountProfileNameValue()..parse('   '),
      throwsA(isA<RequiredValueException>()),
    );
  });

  test('accepts 255 and rejects 256 Unicode code points', () {
    final atMaximum = List<String>.filled(255, '😀').join();
    final overMaximum = '$atMaximum😀';

    expect(
      (AccountProfileNameValue()..parse(atMaximum)).value.runes.length,
      255,
    );
    expect(
      () => AccountProfileNameValue()..parse(overMaximum),
      throwsA(isA<TooLongValueException>()),
    );
  });
}
