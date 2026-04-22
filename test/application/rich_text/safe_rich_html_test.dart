import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonicalizes plain text newlines into faithful HTML blocks', () {
    final html = SafeRichHtml.canonicalize(
      'Primeira linha\nSegunda linha\n\nNovo parágrafo',
    );

    expect(
      html,
      '<p>Primeira linha<br />Segunda linha</p><p>Novo parágrafo</p>',
    );
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
    expect(html, isNot(contains('iframe')));
    expect(html, isNot(contains('remover')));
  });
}
