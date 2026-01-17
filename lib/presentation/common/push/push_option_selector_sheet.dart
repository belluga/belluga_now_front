import 'package:flutter/material.dart';
import 'package:push_handler/push_handler.dart';

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
  late final Set<dynamic> _selectedValues = _resolveInitialSelection();

  Set<dynamic> _resolveInitialSelection() {
    final selected = <dynamic>[];
    selected.addAll(widget.initialSelected);
    selected.addAll(
      widget.options.where((option) => option.isSelected).map((option) => option.value),
    );
    if (selected.isEmpty) {
      return <dynamic>{};
    }
    if (widget.selectionMode == 'single') {
      return {selected.first};
    }
    final max = widget.maxSelected;
    if (max > 0 && selected.length > max) {
      return selected.take(max).toSet();
    }
    return selected.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.title.isNotEmpty
        ? widget.title
        : 'Selecione seus favoritos';
    final bodyText = widget.body;
    final canContinue = _isSelectionValid();

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
                child: _buildOptions(context),
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
  }

  Widget _buildOptions(BuildContext context) {
    switch (widget.layout) {
      case 'grid':
        return _buildGrid(context);
      case 'tags':
      case 'row':
        return _buildChips(context);
      case 'list':
      default:
        return _buildList(context);
    }
  }

  Widget _buildList(BuildContext context) {
    return ListView.separated(
      itemCount: widget.options.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final option = widget.options[index];
        final selected = _selectedValues.contains(option.value);
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

  Widget _buildGrid(BuildContext context) {
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
        final selected = _selectedValues.contains(option.value);
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
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            option.image!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
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

  Widget _buildChips(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.options.map((option) {
          final selected = _selectedValues.contains(option.value);
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
    final isSelected = _selectedValues.contains(option.value);
    final selectionMode = widget.selectionMode;
    if (selectionMode == 'single') {
      setState(() {
        if (isSelected) {
          _selectedValues.remove(option.value);
          return;
        }
        _selectedValues
          ..clear()
          ..add(option.value);
      });
      return;
    }
    final max = widget.maxSelected;
    if (!isSelected && max > 0 && _selectedValues.length >= max) {
      return;
    }
    setState(() {
      if (isSelected) {
        _selectedValues.remove(option.value);
      } else {
        _selectedValues.add(option.value);
      }
    });
  }

  bool _isSelectionValid() {
    final selectionMode = widget.selectionMode;
    if (selectionMode == 'single') {
      return _selectedValues.length == 1;
    }
    final min = widget.minSelected;
    final max = widget.maxSelected;
    if (max > 0 && _selectedValues.length > max) {
      return false;
    }
    if (min <= 0) {
      return true;
    }
    return _selectedValues.length >= min;
  }

  void _closeSheet() {
    Navigator.of(context).pop(_selectedValues.toList());
  }
}
