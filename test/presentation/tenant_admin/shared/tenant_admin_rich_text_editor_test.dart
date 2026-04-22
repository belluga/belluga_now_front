import 'package:belluga_now/application/rich_text/account_profile_rich_text_limits.dart';
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
