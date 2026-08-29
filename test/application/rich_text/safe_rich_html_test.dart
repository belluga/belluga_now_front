import 'dart:convert';
import 'dart:io';

import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixtureText(
  Map<String, dynamic> fixture,
  String directKey,
  String repeatKey,
) {
  final direct = fixture[directKey];
  if (direct is String) return direct;

  final repeat = fixture[repeatKey] as Map<String, dynamic>;
  final fragment = repeat['fragment'] as String;
  final count = repeat['count'] as int;
  return '${repeat['prefix'] as String}'
      '${List<String>.filled(count, fragment).join()}'
      '${repeat['suffix'] as String}';
}

String _unterminatedAnchorSequence(int count) =>
    '<p>${List<String>.filled(count, '<a href="https://example.test/unclosed">x').join()}</p>';

String _unterminatedQuotedAnchorCandidates(int count) =>
    '<p><a href="https://example.test/valid">valid</a></p>'
    '${List<String>.filled(count, '<a href="').join()}';

String _manyValidAnchors(int count) =>
    '<p>${List<String>.filled(count, '<a href="https://example.test/valid">x</a>').join()}</p>';

int _bestSanitizationMicros(String input) {
  var best = 1 << 62;
  for (var sample = 0; sample < 3; sample++) {
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < 3; iteration++) {
      SafeRichHtml.canonicalize(input, allowExplicitHttpsLinks: true);
    }
    stopwatch.stop();
    if (stopwatch.elapsedMicroseconds < best) {
      best = stopwatch.elapsedMicroseconds;
    }
  }
  return best;
}

void main() {
  test('matches the shared cross-stack sanitizer fixtures', () {
    final localFixture = File(
      'test/fixtures/shared_rich_text/safe_rich_html_fixtures.json',
    );
    final backendFixture = File(
      '../laravel-app/tests/Fixtures/shared_rich_text/safe_rich_html_fixtures.json',
    );

    expect(localFixture.existsSync(), isTrue);
    if (backendFixture.existsSync()) {
      expect(
        localFixture.readAsStringSync(),
        backendFixture.readAsStringSync(),
        reason: 'Flutter and Laravel rich-text fixtures must stay in sync.',
      );
    }

    final fixtures =
        jsonDecode(localFixture.readAsStringSync()) as List<dynamic>;

    for (final fixture in fixtures.cast<Map<String, dynamic>>()) {
      final input = _fixtureText(fixture, 'input', 'input_repeat');
      final expected = _fixtureText(fixture, 'expected', 'expected_repeat');
      expect(
        SafeRichHtml.canonicalize(input),
        expected,
        reason: fixture['name'] as String,
      );
      if (fixture['explicit_https_expected'] is String ||
          fixture['explicit_https_expected_repeat'] is Map<String, dynamic>) {
        final explicitHttpsExpected = _fixtureText(
          fixture,
          'explicit_https_expected',
          'explicit_https_expected_repeat',
        );
        final canonical = SafeRichHtml.canonicalize(
          input,
          allowExplicitHttpsLinks: true,
        );
        expect(
          canonical,
          explicitHttpsExpected,
          reason: fixture['name'] as String,
        );
        expect(
          SafeRichHtml.canonicalize(canonical, allowExplicitHttpsLinks: true),
          explicitHttpsExpected,
          reason: '${fixture['name']} must be idempotent',
        );
      }
    }
  });

  test('unterminated anchor preflight grows proportionately near 100 KB', () {
    final smaller = _unterminatedAnchorSequence(800);
    final nearLimit = _unterminatedAnchorSequence(2450);

    expect(nearLimit.length, lessThanOrEqualTo(102400));
    expect(nearLimit.length, greaterThan(98000));
    expect(
      SafeRichHtml.canonicalize(nearLimit, allowExplicitHttpsLinks: true),
      '<p>${List<String>.filled(2450, 'x').join()}</p>',
    );

    // A 3.06x input increase has a deliberately loose 6x budget. The former
    // repeated forward matching grows quadratically and exceeds this ratio.
    final smallerMicros = _bestSanitizationMicros(smaller);
    final nearLimitMicros = _bestSanitizationMicros(nearLimit);
    expect(nearLimitMicros, lessThanOrEqualTo(smallerMicros * 6));
    expect(nearLimitMicros, lessThan(2000000));
  });

  test(
    'quoted unterminated anchor candidates after a valid prefix stay linear',
    () {
      final smaller = _unterminatedQuotedAnchorCandidates(2500);
      final nearLimit = _unterminatedQuotedAnchorCandidates(10000);

      expect(nearLimit.length, lessThanOrEqualTo(102400));
      expect(nearLimit.length, greaterThan(90000));
      expect(
        SafeRichHtml.canonicalize(nearLimit, allowExplicitHttpsLinks: true),
        '<p><a href="https://example.test/valid">valid</a></p>',
      );

      // The 4x input increase has a loose 8x budget. A scanner that restarts
      // at every nested `<a` candidate grows quadratically and exceeds it.
      final smallerMicros = _bestSanitizationMicros(smaller);
      final nearLimitMicros = _bestSanitizationMicros(nearLimit);
      expect(nearLimitMicros, lessThanOrEqualTo(smallerMicros * 8));
      expect(nearLimitMicros, lessThan(2000000));
    },
  );

  test('many valid anchors grow proportionately near 100 KB', () {
    final smaller = _manyValidAnchors(550);
    final nearLimit = _manyValidAnchors(2200);

    expect(nearLimit.length, lessThanOrEqualTo(102400));
    expect(nearLimit.length, greaterThan(90000));
    expect(
      SafeRichHtml.canonicalize(nearLimit, allowExplicitHttpsLinks: true),
      nearLimit,
    );

    final smallerMicros = _bestSanitizationMicros(smaller);
    final nearLimitMicros = _bestSanitizationMicros(nearLimit);
    expect(nearLimitMicros, lessThanOrEqualTo(smallerMicros * 8));
    expect(nearLimitMicros, lessThan(2000000));
  });

  test('canonicalizes plain text newlines into faithful HTML blocks', () {
    final html = SafeRichHtml.canonicalize(
      'Primeira linha\nSegunda linha\n\nNovo parágrafo',
    );

    expect(
      html,
      '<p>Primeira linha<br />Segunda linha</p><p>Novo parágrafo</p>',
    );
  });

  test(
    'escapes angle-bracketed placeholders instead of treating them as html',
    () {
      expect(SafeRichHtml.looksLikeHtml('Use <token> here'), isFalse);
      expect(
        SafeRichHtml.canonicalize('Use <token> here'),
        '<p>Use &lt;token&gt; here</p>',
      );
    },
  );

  test(
    'sanitizes unsupported but valid html tags instead of escaping them',
    () {
      final html = SafeRichHtml.canonicalize(
        '<b>bold</b><table><tr><td>cell</td></tr></table>',
      );

      expect(SafeRichHtml.looksLikeHtml('<b>bold</b>'), isTrue);
      expect(html, contains('bold'));
      expect(html, contains('cell'));
      expect(html, isNot(contains('<b>')));
      expect(html, isNot(contains('<table>')));
    },
  );

  test('preserves the approved safe subset and strips unsupported markup', () {
    final html = SafeRichHtml.canonicalize(
      '<h2>Título seguro</h2>'
      '<p><strong>Forte</strong> <em>ênfase</em> '
      '<s>riscado</s> 😄 <a href="https://example.test">link texto</a></p>'
      '<blockquote>Citação</blockquote>'
      '<ul><li>Item um</li><li>Item dois</li></ul>'
      '<ol><li>Passo um</li></ol>'
      '<script>remover script</script>'
      '<iframe>remover iframe</iframe>',
    );

    expect(html, contains('<h2>Título seguro</h2>'));
    expect(html, contains('<strong>Forte</strong>'));
    expect(html, contains('<em>ênfase</em>'));
    expect(html, contains('<s>riscado</s>'));
    expect(html, contains('😄'));
    expect(html, contains('link texto'));
    expect(html, contains('<blockquote>Citação</blockquote>'));
    expect(html, contains('<ul><li>Item um</li><li>Item dois</li></ul>'));
    expect(html, contains('<ol><li>Passo um</li></ol>'));
    expect(html, isNot(contains('<a')));
    expect(html, isNot(contains('href')));
    expect(html, isNot(contains('script')));
    expect(html, isNot(contains('<iframe')));
    expect(html, isNot(contains('</iframe>')));
    expect(html, isNot(contains('remover script')));
    expect(html, contains('remover iframe'));
  });
}
