import 'package:belluga_now/application/rich_text/account_profile_rich_text_limits.dart';
import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows account profile 100 KB guidance and counters for bio and content',
    (tester) async {
      final bioController = TextEditingController(text: '<p>Bio curta</p>');
      final contentController = TextEditingController(
        text: '<p>Conteúdo curto</p>',
      );
      addTearDown(bioController.dispose);
      addTearDown(contentController.dispose);

      await tester.pumpWidget(
        _buildEditorHost(
          children: [
            TenantAdminRichTextEditor(
              controller: bioController,
              label: 'Bio',
              maxContentBytes: accountProfileRichTextMaxBytes,
              warningThreshold: accountProfileRichTextWarningThreshold,
            ),
            TenantAdminRichTextEditor(
              controller: contentController,
              label: 'Conteúdo',
              maxContentBytes: accountProfileRichTextMaxBytes,
              warningThreshold: accountProfileRichTextWarningThreshold,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(
        find.text('Limite: 100 KB por campo. O backend valida o envio final.'),
        findsNWidgets(2),
      );
      expect(find.textContaining('/ 100 KB'), findsNWidgets(2));
    },
  );

  testWidgets('shows a soft warning around 90 percent of the field limit',
      (tester) async {
    final warningText = List<String>.filled(92 * 1024, 'a').join();
    final controller = TextEditingController(text: '<p>$warningText</p>');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildEditorHost(
        children: [
          TenantAdminRichTextEditor(
            controller: controller,
            label: 'Bio',
            maxContentBytes: accountProfileRichTextMaxBytes,
            warningThreshold: accountProfileRichTextWarningThreshold,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('Este campo já passou de 90% do limite de 100 KB.'),
      findsOneWidget,
    );
    expect(find.textContaining('/ 100 KB'), findsOneWidget);
  });

  testWidgets('uses shared safe rich html policy for imported markup',
      (tester) async {
    final controller = TextEditingController(
      text: '<p>Texto seguro</p><iframe>remover iframe</iframe><img src="x" />',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildEditorHost(
        children: [
          TenantAdminRichTextEditor(
            controller: controller,
            label: 'Bio',
            maxContentBytes: accountProfileRichTextMaxBytes,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(controller.text, contains('Texto seguro'));
    expect(controller.text, isNot(contains('<iframe')));
    expect(controller.text, contains('remover iframe'));
    expect(controller.text, isNot(contains('<img')));
  });

  test(
    'safe rich html unwraps unsupported containers while removing dangerous content',
    () {
      final sanitized = SafeRichHtml.canonicalize(
        '<div>Antes <iframe>texto interno</iframe> <u>under</u> after</div>'
        '<script>alert(1)</script><style>.x{}</style>',
      );

      expect(sanitized, '<p>Antes texto interno under after</p>');
      expect(sanitized, isNot(contains('<iframe')));
      expect(sanitized, isNot(contains('<u>')));
      expect(sanitized, isNot(contains('alert')));
      expect(sanitized, isNot(contains('<style')));
    },
  );
}

Widget _buildEditorHost({
  required List<Widget> children,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
