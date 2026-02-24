import 'package:stream_value/core/stream_value.dart';

class PushOptionSelectorController {
  PushOptionSelectorController({
    required String selectionMode,
    required int minSelected,
    required int maxSelected,
    required List<dynamic> initialSelected,
    required List<dynamic> optionDefaults,
  })  : _selectionMode = selectionMode,
        _minSelected = minSelected,
        _maxSelected = maxSelected,
        _selectedValuesStreamValue = StreamValue<Set<dynamic>>(
          defaultValue: _resolveInitialSelection(
            selectionMode: selectionMode,
            minSelected: minSelected,
            maxSelected: maxSelected,
            initialSelected: initialSelected,
            optionDefaults: optionDefaults,
          ),
        );

  final String _selectionMode;
  final int _minSelected;
  final int _maxSelected;
  final StreamValue<Set<dynamic>> _selectedValuesStreamValue;

  StreamValue<Set<dynamic>> get selectedValuesStreamValue =>
      _selectedValuesStreamValue;
  Set<dynamic> get selectedValues => _selectedValuesStreamValue.value;

  void toggle(dynamic value) {
    final current = Set<dynamic>.from(selectedValues);
    final isSelected = current.contains(value);
    if (_selectionMode == 'single') {
      if (isSelected) {
        current.remove(value);
        _selectedValuesStreamValue.addValue(current);
        return;
      }
      current
        ..clear()
        ..add(value);
      _selectedValuesStreamValue.addValue(current);
      return;
    }
    if (!isSelected && _maxSelected > 0 && current.length >= _maxSelected) {
      return;
    }
    if (isSelected) {
      current.remove(value);
    } else {
      current.add(value);
    }
    _selectedValuesStreamValue.addValue(current);
  }

  bool isSelectionValid() {
    if (_selectionMode == 'single') {
      return selectedValues.length == 1;
    }
    if (_maxSelected > 0 && selectedValues.length > _maxSelected) {
      return false;
    }
    if (_minSelected <= 0) {
      return true;
    }
    return selectedValues.length >= _minSelected;
  }

  void dispose() {
    _selectedValuesStreamValue.dispose();
  }

  static Set<dynamic> _resolveInitialSelection({
    required String selectionMode,
    required int minSelected,
    required int maxSelected,
    required List<dynamic> initialSelected,
    required List<dynamic> optionDefaults,
  }) {
    final selected = <dynamic>[];
    selected.addAll(initialSelected);
    selected.addAll(optionDefaults);
    if (selected.isEmpty) {
      return <dynamic>{};
    }
    if (selectionMode == 'single') {
      return {selected.first};
    }
    if (maxSelected > 0 && selected.length > maxSelected) {
      return selected.take(maxSelected).toSet();
    }
    return selected.toSet();
  }
}
