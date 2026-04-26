import 'dart:convert';
import 'dart:io';

import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(
        SafeRichHtml.canonicalize(fixture['input'] as String),
        fixture['expected'] as String,
        reason: fixture['name'] as String,
      );
    }
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

  test('escapes angle-bracketed placeholders instead of treating them as html',
      () {
    expect(SafeRichHtml.looksLikeHtml('Use <token> here'), isFalse);
    expect(
      SafeRichHtml.canonicalize('Use <token> here'),
      '<p>Use &lt;token&gt; here</p>',
    );
  });

  test('sanitizes unsupported but valid html tags instead of escaping them',
      () {
    final html = SafeRichHtml.canonicalize(
      '<b>bold</b><table><tr><td>cell</td></tr></table>',
    );

    expect(SafeRichHtml.looksLikeHtml('<b>bold</b>'), isTrue);
    expect(html, contains('bold'));
    expect(html, contains('cell'));
    expect(html, isNot(contains('<b>')));
    expect(html, isNot(contains('<table>')));
  });

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
