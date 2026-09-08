import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_item.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_group_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_item_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_gallery_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'item editor submits and clears title independently from description',
    (tester) async {
      final titleCalls = <List<String>>[];
      await _pumpEditor(
        tester,
        groups: [_group('group-1', itemCount: 1)],
        maxGroups: 2,
        maxItems: 2,
        onTitleChanged: (groupId, itemId, title) async {
          titleCalls.add([groupId, itemId, title]);
        },
      );

      final titleField = find.byKey(
        const Key('tenantAdminGalleryItemTitle_group-1-item-0'),
      );
      expect(titleField, findsOneWidget);
      expect(
        find.byKey(
          const Key('tenantAdminGalleryItemDescription_group-1-item-0'),
        ),
        findsOneWidget,
      );

      await tester.enterText(titleField, 'Um minuto na praia');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.enterText(titleField, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(titleCalls, [
        ['group-1', 'group-1-item-0', 'Um minuto na praia'],
        ['group-1', 'group-1-item-0', ''],
      ]);
    },
  );

  testWidgets(
    'title and description mount uniquely and adopt a new authoritative snapshot',
    (tester) async {
      await _pumpEditor(
        tester,
        groups: [
          _group(
            'group-1',
            itemCount: 1,
            title: 'Título anterior',
            description: 'Descrição anterior',
          ),
        ],
        maxGroups: 2,
        maxItems: 2,
      );

      expect(tester.takeException(), isNull);
      expect(
        _fieldText(tester, 'tenantAdminGalleryItemTitle_group-1-item-0'),
        'Título anterior',
      );
      expect(
        _fieldText(tester, 'tenantAdminGalleryItemDescription_group-1-item-0'),
        'Descrição anterior',
      );

      await _pumpEditor(
        tester,
        groups: [
          _group(
            'group-1',
            itemCount: 1,
            title: 'Título canônico',
            description: 'Descrição canônica',
          ),
        ],
        maxGroups: 2,
        maxItems: 2,
      );

      expect(tester.takeException(), isNull);
      expect(
        _fieldText(tester, 'tenantAdminGalleryItemTitle_group-1-item-0'),
        'Título canônico',
      );
      expect(
        _fieldText(tester, 'tenantAdminGalleryItemDescription_group-1-item-0'),
        'Descrição canônica',
      );
    },
  );

  testWidgets(
    'validation errors render at their controls and preserve correctable input',
    (tester) async {
      final groups = [_group('group-1', itemCount: 1)];
      final fieldErrors = ValueNotifier<Map<String, String>>(const {});
      addTearDown(fieldErrors.dispose);
      await _pumpEditor(
        tester,
        groups: groups,
        maxGroups: 2,
        maxItems: 2,
        fieldErrorsNotifier: fieldErrors,
      );
      final titleField = find.byKey(
        const Key('tenantAdminGalleryItemTitle_group-1-item-0'),
      );
      await tester.enterText(titleField, 'Título corrigível');

      fieldErrors.value = const {
        'group.create.subtitle': 'Não foi possível criar o grupo.',
        'group.group-1.subtitle': 'Nome inválido.',
        'group.group-1.item.create.image': 'Imagem inválida.',
        'group.group-1.item.group-1-item-0.title': 'Título inválido.',
        'group.group-1.item.group-1-item-0.description': 'Descrição inválida.',
        'group.group-1.item.group-1-item-0.image':
            'Não foi possível trocar a foto.',
        'gallery_capabilities.max_galleries': 'Limite do plano atingido.',
      };
      await tester.pump();

      expect(
        find.byKey(const Key('tenantAdminGalleryGroupSubtitleError_group-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('tenantAdminGalleryItemTitleError_group-1-item-0'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('tenantAdminGalleryItemDescriptionError_group-1-item-0'),
        ),
        findsOneWidget,
      );
      expect(
        _fieldText(tester, 'tenantAdminGalleryItemTitle_group-1-item-0'),
        'Título corrigível',
      );
      expect(
        find.byKey(const Key('tenantAdminGalleryCreateGroupError')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminGalleryGroupAddPhotoError_group-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('tenantAdminGalleryItemProviderError_group-1-item-0'),
        ),
        findsOneWidget,
      );
      expect(find.text('Limite do plano atingido.'), findsOneWidget);
    },
  );

  testWidgets('operation failure remains visible in the gallery section', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      groups: [_group('group-1', itemCount: 1)],
      maxGroups: 2,
      maxItems: 2,
      operationError: 'Não foi possível salvar a alteração.',
    );

    expect(
      find.byKey(const Key('tenantAdminGalleryOperationError')),
      findsOneWidget,
    );
    expect(find.text('Não foi possível salvar a alteração.'), findsOneWidget);
  });

  testWidgets('available capacity keeps group and item additions enabled', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      groups: [_group('group-1', itemCount: 1)],
      maxGroups: 2,
      maxItems: 2,
    );

    expect(find.text('1 / 2 galerias · disponível'), findsOneWidget);
    expect(find.text('1 / 2 itens · disponível'), findsOneWidget);
    expect(
      _button(tester, 'tenantAdminEditAddGalleryGroupButton').onPressed,
      isNotNull,
    );
    expect(
      _button(tester, 'tenantAdminGalleryGroupAddPhoto_group-1').onPressed,
      isNotNull,
    );
    expect(
      _button(tester, 'tenantAdminGalleryGroupAddYoutube_group-1').onPressed,
      isNotNull,
    );
  });

  testWidgets('at-plan limits block only additions and preserve remediation', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      groups: [_group('group-1', itemCount: 1)],
      maxGroups: 1,
      maxItems: 1,
    );

    expect(find.text('1 / 1 galerias · no limite do plano'), findsOneWidget);
    expect(find.text('1 / 1 itens · no limite do plano'), findsOneWidget);
    expect(
      _button(tester, 'tenantAdminEditAddGalleryGroupButton').onPressed,
      isNull,
    );
    expect(
      _button(tester, 'tenantAdminGalleryGroupAddPhoto_group-1').onPressed,
      isNull,
    );
    expect(
      _button(tester, 'tenantAdminGalleryGroupAddYoutube_group-1').onPressed,
      isNull,
    );
    expect(_iconButton(tester, 'Remover grupo').onPressed, isNotNull);
    expect(_iconButton(tester, 'Remover foto').onPressed, isNotNull);
  });

  testWidgets('over-plan groups and items explain the required removals', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      groups: [_group('group-1', itemCount: 2), _group('group-2')],
      maxGroups: 1,
      maxItems: 1,
    );

    expect(
      find.text('2 / 1 galerias · acima do limite do plano'),
      findsOneWidget,
    );
    expect(find.text('2 / 1 itens · acima do limite do plano'), findsOneWidget);
    expect(find.textContaining('Remova pelo menos 1 galeria'), findsOneWidget);
    expect(find.textContaining('Remova pelo menos 1 item'), findsOneWidget);
    expect(
      _button(tester, 'tenantAdminEditAddGalleryGroupButton').onPressed,
      isNull,
    );
    expect(
      _button(tester, 'tenantAdminGalleryGroupAddPhoto_group-1').onPressed,
      isNull,
    );
    expect(
      _button(tester, 'tenantAdminGalleryGroupAddYoutube_group-1').onPressed,
      isNull,
    );
    expect(_iconButton(tester, 'Remover grupo').onPressed, isNotNull);
    expect(_iconButton(tester, 'Remover foto').onPressed, isNotNull);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required List<TenantAdminAccountProfileGalleryGroupDraft> groups,
  required int maxGroups,
  required int maxItems,
  Map<String, String> fieldErrors = const {},
  String? operationError,
  ValueNotifier<Map<String, String>>? fieldErrorsNotifier,
  Future<void> Function(String groupId, String itemId, String title)?
  onTitleChanged,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  Future<void> done([Object? _, Object? _, Object? _]) async {}
  final inputValues = <String, String>{};

  Widget editor(Map<String, String> errors) =>
      TenantAdminAccountProfileGalleryEditor(
        groups: groups,
        maxGroups: maxGroups,
        maxItemsPerGallery: maxItems,
        busy: false,
        fieldErrors: errors,
        operationError: operationError,
        resolveInputValue: (fieldPath, authoritativeValue) =>
            inputValues[fieldPath] ?? authoritativeValue,
        onInputChanged: (fieldPath, value) => inputValues[fieldPath] = value,
        onAddGroup: done,
        onRenameGroup: (groupId, subtitle) => done(),
        onMoveGroup: (groupId, delta) => done(),
        onRemoveGroup: (groupId) => done(),
        onAddPhotoRequested: (groupId) => done(),
        onAddYoutubeRequested: (groupId) => done(),
        onReplaceItemRequested: (groupId, itemId) => done(),
        onMoveItem: (groupId, itemId, delta) => done(),
        onRemoveItem: (groupId, itemId) => done(),
        onTitleChanged: onTitleChanged ?? (groupId, itemId, title) => done(),
        onDescriptionChanged: (groupId, itemId, description) => done(),
      );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: fieldErrorsNotifier == null
              ? editor(fieldErrors)
              : ValueListenableBuilder<Map<String, String>>(
                  valueListenable: fieldErrorsNotifier,
                  builder: (context, errors, _) => editor(errors),
                ),
        ),
      ),
    ),
  );
  await tester.pump();
}

TenantAdminAccountProfileGalleryGroupDraft _group(
  String id, {
  int itemCount = 0,
  String? title,
  String? description,
}) {
  return TenantAdminAccountProfileGalleryGroupDraft(
    groupId: id,
    subtitle: id,
    order: 0,
    items: List.generate(
      itemCount,
      (index) => TenantAdminAccountProfileGalleryItemDraft(
        itemId: '$id-item-$index',
        order: index,
        type: TenantAdminAccountProfileGalleryItemType.photo,
        title: title,
        description: description,
      ),
    ),
  );
}

OutlinedButton _button(WidgetTester tester, String key) =>
    tester.widget<OutlinedButton>(find.byKey(Key(key)));

IconButton _iconButton(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip).first,
        matching: find.byType(IconButton),
      ),
    );

String _fieldText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;
