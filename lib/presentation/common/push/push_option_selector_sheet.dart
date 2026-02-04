import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/common/push/controllers/push_option_selector_controller.dart';
import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:push_handler/push_handler.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class PushOptionSelectorSheet extends StatefulWidget {
  const PushOptionSelectorSheet({
    super.key,
    required this.title,
    required this.body,
    required this.layout,
    required this.gridColumns,
    required this.selectionMode,
    required this.options,
    required this.minSelected,
    required this.maxSelected,
    required this.initialSelected,
  });

  final String title;
  final String body;
  final String layout;
  final int gridColumns;
  final String selectionMode;
  final List<OptionItem> options;
  final int minSelected;
  final int maxSelected;
  final List<dynamic> initialSelected;

  static Future<List<dynamic>?> show({
    required BuildContext context,
    required String title,
    required String body,
    required String layout,
    required int gridColumns,
    required String selectionMode,
    required List<OptionItem> options,
    required int minSelected,
    required int maxSelected,
    required List<dynamic> initialSelected,
  }) {
    return showModalBottomSheet<List<dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: PushOptionSelectorSheet(
            title: title,
            body: body,
            layout: layout,
            gridColumns: gridColumns,
            selectionMode: selectionMode,
            options: options,
            minSelected: minSelected,
            maxSelected: maxSelected,
            initialSelected: initialSelected,
          ),
        );
      },
    );
  }

  @override
  State<PushOptionSelectorSheet> createState() =>
      _PushOptionSelectorSheetState();
}

class _PushOptionSelectorSheetState extends State<PushOptionSelectorSheet> {
  late final PushOptionSelectorController _controller = _buildController();

  PushOptionSelectorController _buildController() {
    final defaults = widget.options
        .where((option) => option.isSelected)
        .map((option) => option.value)
        .toList();
    return PushOptionSelectorController(
      selectionMode: widget.selectionMode,
      minSelected: widget.minSelected,
      maxSelected: widget.maxSelected,
      initialSelected: widget.initialSelected,
      optionDefaults: defaults,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.title.isNotEmpty
        ? widget.title
        : 'Selecione seus favoritos';
    final bodyText = widget.body;
    return StreamValueBuilder<Set<dynamic>>(
      streamValue: _controller.selectedValuesStreamValue,
      builder: (context, selectedValues) {
        final canContinue = _controller.isSelectionValid();
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(titleText),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _closeSheet,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bodyText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      bodyText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildOptions(context, selectedValues),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canContinue ? _closeSheet : null,
                      child: const Text('Continuar'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptions(
    BuildContext context,
    Set<dynamic> selectedValues,
  ) {
    switch (widget.layout) {
      case 'grid':
        return _buildGrid(context, selectedValues);
      case 'tags':
      case 'row':
        return _buildChips(context, selectedValues);
      case 'list':
      default:
        return _buildList(context, selectedValues);
    }
  }

  Widget _buildList(BuildContext context, Set<dynamic> selectedValues) {
    return ListView.separated(
      itemCount: widget.options.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final option = widget.options[index];
        final selected = selectedValues.contains(option.value);
        final title = option.label ?? option.value?.toString() ?? '';
        final subtitle = option.subtitle;
        return CheckboxListTile(
          value: selected,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          onChanged: (_) => _toggle(option),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, Set<dynamic> selectedValues) {
    final columns = widget.gridColumns <= 0 ? 2 : widget.gridColumns;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: widget.options.length,
      itemBuilder: (context, index) {
        final option = widget.options[index];
        final selected = selectedValues.contains(option.value);
        final title = option.label ?? option.value?.toString() ?? '';
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggle(option),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
              color: selected
                  ? Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.08,
                      )
                  : Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: option.image != null && option.image!.isNotEmpty
                      ? BellugaNetworkImage(
                          option.image!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          clipBorderRadius: BorderRadius.circular(8),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChips(BuildContext context, Set<dynamic> selectedValues) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.options.map((option) {
          final selected = selectedValues.contains(option.value);
          final title = option.label ?? option.value?.toString() ?? '';
          return option.customWidgetBuilder != null
              ? InkWell(
                  onTap: () => _toggle(option),
                  child: option.customWidgetBuilder!(
                    context,
                    selected,
                  ),
                )
              : FilterChip(
                  label: Text(title),
                  selected: selected,
                  onSelected: (_) => _toggle(option),
                );
        }).toList(),
      ),
    );
  }

  void _toggle(OptionItem option) {
    _controller.toggle(option.value);
  }

  void _closeSheet() {
    context.router.pop(_controller.selectedValues.toList());
  }
}
