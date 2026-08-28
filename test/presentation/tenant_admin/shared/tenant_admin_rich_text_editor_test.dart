import 'dart:ui' show SemanticsInputType, Tristate;

import 'package:belluga_now/application/rich_text/account_profile_rich_text_limits.dart';
import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

void main() {
  test(
    'configures package link output without non-policy target attributes',
    () {
      final delta = <Map<String, dynamic>>[
        <String, dynamic>{
          'insert': 'Belluga HTTPS runtime link',
          'attributes': <String, dynamic>{
            'link': 'https://example.com/belluga-rich-text-event',
          },
        },
        <String, dynamic>{'insert': '\n'},
      ];
      expect(
        QuillDeltaToHtmlConverter(delta, ConverterOptions.forEmail()).convert(),
        '<p><a href="https://example.com/belluga-rich-text-event" '
        'target="_blank">Belluga HTTPS runtime link</a></p>',
      );

      final canonicalOptions = ConverterOptions.forEmail();
      canonicalOptions.converterOptions.linkTarget = '';
      expect(
        QuillDeltaToHtmlConverter(delta, canonicalOptions).convert(),
        '<p><a href="https://example.com/belluga-rich-text-event">'
        'Belluga HTTPS runtime link</a></p>',
      );
    },
  );

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

  testWidgets('shows a soft warning around 90 percent of the field limit', (
    tester,
  ) async {
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

  testWidgets('uses shared safe rich html policy for imported markup', (
    tester,
  ) async {
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

  testWidgets('renders the rich editor body with the configured label', (
    tester,
  ) async {
    final controller = TextEditingController(text: '<p>Conteúdo curto</p>');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildEditorHost(
        children: [
          TenantAdminRichTextEditor(
            controller: controller,
            label: 'Título / copy do item',
            placeholder: 'Escreva o conteúdo do item de programação',
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Título / copy do item'), findsOneWidget);
    expect(find.byType(TenantAdminRichTextEditor), findsOneWidget);
  });

  testWidgets(
    'exposes enabled text authoring and selection semantics actions',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildEditorHost(
          children: [
            TenantAdminRichTextEditor(
              controller: controller,
              label: 'Descrição (opcional)',
              allowExplicitHttpsLinks: true,
            ),
          ],
        ),
      );
      await tester.pump();

      final node = tester.getSemantics(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Descrição (opcional)',
        ),
      );
      final flags = node.getSemanticsData().flagsCollection;
      expect(flags.isEnabled, Tristate.isTrue);
      expect(flags.isFocused, isNot(Tristate.none));
      expect(flags.isTextField, isTrue);
      expect(flags.isReadOnly, isFalse);
      expect(node.getSemanticsData().inputType, SemanticsInputType.text);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Descrição (opcional)' &&
              widget.properties.textField == true,
        ),
        findsOneWidget,
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.focus), isTrue);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.setText),
        isTrue,
      );
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.setSelection),
        isTrue,
      );

      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.focus,
          nodeId: node.id,
          viewId: tester.view.viewId,
        ),
      );
      await tester.pumpAndSettle();
      final focusedNode = tester.getSemantics(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Descrição (opcional)',
        ),
      );
      expect(
        focusedNode.getSemanticsData().flagsCollection.isFocused,
        Tristate.isTrue,
      );
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.setText,
          nodeId: focusedNode.id,
          viewId: tester.view.viewId,
          arguments: 'Belluga HTTPS runtime link',
        ),
      );
      await tester.pump();
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.setSelection,
          nodeId: focusedNode.id,
          viewId: tester.view.viewId,
          arguments: <dynamic, dynamic>{'base': 0, 'extent': 26},
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Texto'), findsOneWidget);
      expect(find.text('Link'), findsOneWidget);
      final dialogFields = tester
          .widgetList<TextFormField>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextFormField),
            ),
          )
          .toList();
      expect(dialogFields, hasLength(2));
      expect(dialogFields.first.controller?.text, 'Belluga HTTPS runtime link');
      final linkField = find.widgetWithText(TextFormField, 'Link');
      final okButton = find.widgetWithText(TextButton, 'Ok');
      for (final invalidHref in <String>[
        'http://example.com',
        'javascript:alert(1)',
        'data:text/plain,unsafe',
        '/relative/path',
        'https://user@example.com/private',
        ' https://example.com/space',
        'https://example.com/line break',
        'https:///missing-host',
        'https://example.com/%20space',
        'https://example.com/%0Acontrol',
        r'https://example.com\backslash',
        'https://example.com/"quote',
        'https://example.com/<path',
        'https://example.com/>path',
        'https://example.com/{path',
        'https://example.com/}path',
        "https://example.com/it's",
        'https://example.com/%GG',
        'https://example.com:01/path',
        'https://example.com:080/path',
        'https://example.com:70000/path',
        'https:////example.com/ambiguous',
        'https://[2001:db8::1/path',
        'https://[2001:db8::1]]/path',
        'https://[2001:db8::gg]/path',
        'https://%65xample.test/path',
        'https://example%2Etest/path',
        'https://example.test%40evil.test/path',
        'https://example.test%3A443/path',
        'not a url',
      ]) {
        await tester.enterText(linkField, invalidHref);
        await tester.pump();
        expect(
          tester.widget<TextButton>(okButton).onPressed,
          isNull,
          reason: 'Invalid explicit href must disable Ok: $invalidHref',
        );
      }
      await tester.enterText(linkField, 'https://example.com/valid');
      await tester.pump();
      expect(tester.widget<TextButton>(okButton).onPressed, isNotNull);
      await tester.enterText(
        linkField,
        'https://[2001:db8::1]:443/valid?a=1&b=2',
      );
      await tester.pump();
      expect(tester.widget<TextButton>(okButton).onPressed, isNotNull);
      await tester.enterText(linkField, 'https://example.com/?a=1&amp=2');
      await tester.pump();
      expect(tester.widget<TextButton>(okButton).onPressed, isNotNull);
      await tester.enterText(
        linkField,
        'https://example.com/user@path?q=person@example.com',
      );
      await tester.pump();
      expect(tester.widget<TextButton>(okButton).onPressed, isNotNull);
      expect(
        SafeRichHtml.isAllowedExplicitHttpsHref(
          'https://example.com/line\nbreak',
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('labels each formatting toolbar by its owning editor', (
    tester,
  ) async {
    final bioController = TextEditingController();
    final contentController = TextEditingController();
    addTearDown(bioController.dispose);
    addTearDown(contentController.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _buildEditorHost(
        children: [
          TenantAdminRichTextEditor(
            controller: bioController,
            label: 'Bio',
            allowExplicitHttpsLinks: true,
          ),
          TenantAdminRichTextEditor(
            controller: contentController,
            label: 'Conteudo',
            allowExplicitHttpsLinks: true,
          ),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Bio toolbar',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Conteudo toolbar',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Bio: Inserir URL'), findsOneWidget);
    expect(find.byTooltip('Conteudo: Inserir URL'), findsOneWidget);

    final bioNode = tester.getSemantics(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Bio',
      ),
    );
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: SemanticsAction.setText,
        nodeId: bioNode.id,
        viewId: tester.view.viewId,
        arguments: 'bio',
      ),
    );
    await tester.pump();
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: SemanticsAction.setSelection,
        nodeId: bioNode.id,
        viewId: tester.view.viewId,
        arguments: <dynamic, dynamic>{'base': 0, 'extent': 3},
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Bio: Inserir URL'));
    await tester.pumpAndSettle();
    final linkField = find.widgetWithText(TextFormField, 'Link');
    await tester.enterText(linkField, 'https://example.test/bio');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Ok'));
    await tester.pumpAndSettle();
    expect(
      bioController.text,
      '<p><a href="https://example.test/bio">bio</a></p>',
    );
    expect(contentController.text, isEmpty);
    semantics.dispose();
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

  testWidgets(
    'selected_link_delta_preserves_explicit_https_href_and_default_denies_other_fields',
    (tester) async {
      final enabledController = TextEditingController();
      final defaultDeniedController = TextEditingController(
        text: '<p><a href="https://example.test/denied">documentação</a></p>',
      );
      addTearDown(enabledController.dispose);
      addTearDown(defaultDeniedController.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildEditorHost(
          children: [
            TenantAdminRichTextEditor(
              controller: enabledController,
              label: 'Conteúdo do evento',
              allowExplicitHttpsLinks: true,
            ),
            TenantAdminRichTextEditor(
              controller: defaultDeniedController,
              label: 'Título de programação',
            ),
          ],
        ),
      );
      await tester.pump();

      final editorNode = tester.getSemantics(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Conteúdo do evento',
        ),
      );
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.setText,
          nodeId: editorNode.id,
          viewId: tester.view.viewId,
          arguments: 'documentação',
        ),
      );
      await tester.pump();
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.setSelection,
          nodeId: editorNode.id,
          viewId: tester.view.viewId,
          arguments: <dynamic, dynamic>{'base': 0, 'extent': 13},
        ),
      );
      await tester.pump();
      final linkButton = find.byTooltip('Conteúdo do evento: Inserir URL');
      await tester.ensureVisible(linkButton);
      await tester.tap(linkButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Link'),
        'https://example.test/docs?a=1&b=2',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Ok'));
      await tester.pumpAndSettle();

      expect(
        enabledController.text,
        '<p><a href="https://example.test/docs?a=1&amp;b=2">documentação</a></p>',
      );
      expect(defaultDeniedController.text, '<p>documentação</p>');
      expect(
        find.byTooltip('Título de programação: Inserir URL'),
        findsNothing,
      );
      semantics.dispose();
    },
  );
}

Widget _buildEditorHost({required List<Widget> children}) {
  return MaterialApp(
    locale: const Locale('pt', 'BR'),
    supportedLocales: const <Locale>[Locale('pt', 'BR')],
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      ...FlutterQuillLocalizations.localizationsDelegates,
    ],
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
