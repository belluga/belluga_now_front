import 'package:flutter/material.dart';

class TenantAdminHtmlToolbar extends StatelessWidget {
  const TenantAdminHtmlToolbar({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  void _insertTag({
    required String openTag,
    required String closeTag,
    String placeholder = 'texto',
  }) {
    final value = controller.value;
    final text = value.text;
    final selection = value.selection;

    final hasSelection = selection.start >= 0 &&
        selection.end >= 0 &&
        selection.start <= selection.end &&
        selection.end <= text.length &&
        selection.start != selection.end;

    final start = hasSelection ? selection.start : text.length;
    final end = hasSelection ? selection.end : text.length;
    final selectedText = hasSelection ? text.substring(start, end) : placeholder;
    final replacement = '$openTag$selectedText$closeTag';
    final nextText = text.replaceRange(start, end, replacement);
    final caretOffset = start + replacement.length;

    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: caretOffset),
      composing: TextRange.empty,
    );
  }

  void _insertSelfClosingTag(String tag) {
    final value = controller.value;
    final text = value.text;
    final selection = value.selection;
    final hasSelection = selection.start >= 0 && selection.end >= 0;
    final insertionOffset = hasSelection ? selection.end : text.length;
    final nextText = text.replaceRange(insertionOffset, insertionOffset, tag);
    final caretOffset = insertionOffset + tag.length;

    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: caretOffset),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonal(
          onPressed: () => _insertTag(
            openTag: '<b>',
            closeTag: '</b>',
          ),
          child: const Text('B'),
        ),
        FilledButton.tonal(
          onPressed: () => _insertTag(
            openTag: '<i>',
            closeTag: '</i>',
          ),
          child: const Text('I'),
        ),
        FilledButton.tonal(
          onPressed: () => _insertTag(
            openTag: '<p>',
            closeTag: '</p>',
          ),
          child: const Text('P'),
        ),
        FilledButton.tonal(
          onPressed: () => _insertTag(
            openTag: '<h3>',
            closeTag: '</h3>',
            placeholder: 'titulo',
          ),
          child: const Text('H3'),
        ),
        FilledButton.tonal(
          onPressed: () => _insertTag(
            openTag: '<a href="">',
            closeTag: '</a>',
            placeholder: 'link',
          ),
          child: const Text('Link'),
        ),
        FilledButton.tonal(
          onPressed: () => _insertSelfClosingTag('<br/>'),
          child: const Text('BR'),
        ),
      ],
    );
  }
}
