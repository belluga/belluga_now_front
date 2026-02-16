import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class TenantAdminRichTextEditor extends StatefulWidget {
  const TenantAdminRichTextEditor({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.minHeight = 180,
  });

  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final double minHeight;

  @override
  State<TenantAdminRichTextEditor> createState() =>
      _TenantAdminRichTextEditorState();
}

class _TenantAdminRichTextEditorState extends State<TenantAdminRichTextEditor> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late QuillController _quillController;
  StreamSubscription? _documentChangesSubscription;
  bool _syncingFromHtmlController = false;
  bool _syncingToHtmlController = false;

  @override
  void initState() {
    super.initState();
    _quillController = _buildQuillController(widget.controller.text);
    widget.controller.addListener(_handleExternalHtmlChange);
    _bindDocumentChanges();
  }

  @override
  void didUpdateWidget(covariant TenantAdminRichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleExternalHtmlChange);
    widget.controller.addListener(_handleExternalHtmlChange);
    _replaceQuillController(
      _buildQuillController(widget.controller.text),
    );
  }

  @override
  void dispose() {
    _documentChangesSubscription?.cancel();
    widget.controller.removeListener(_handleExternalHtmlChange);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _bindDocumentChanges() {
    _documentChangesSubscription?.cancel();
    _documentChangesSubscription =
        _quillController.document.changes.listen((_) {
      _syncHtmlControllerFromDocument();
    });
  }

  void _replaceQuillController(QuillController nextController) {
    _documentChangesSubscription?.cancel();
    setState(() {
      _quillController = nextController;
    });
    _bindDocumentChanges();
  }

  void _handleExternalHtmlChange() {
    if (_syncingToHtmlController) {
      return;
    }
    final targetHtml = widget.controller.text;
    final currentHtml = _deltaToHtml(_quillController);
    if (_normalizeHtml(targetHtml) == _normalizeHtml(currentHtml)) {
      return;
    }
    _syncingFromHtmlController = true;
    _replaceQuillController(
      _buildQuillController(
        targetHtml,
        fallbackSelectionOffset: _quillController.selection.baseOffset,
      ),
    );
    _syncingFromHtmlController = false;
  }

  void _syncHtmlControllerFromDocument() {
    if (_syncingFromHtmlController) {
      return;
    }
    final html = _deltaToHtml(_quillController);
    if (_normalizeHtml(widget.controller.text) == _normalizeHtml(html)) {
      return;
    }
    _syncingToHtmlController = true;
    widget.controller.value = widget.controller.value.copyWith(
      text: html,
      selection: TextSelection.collapsed(offset: html.length),
      composing: TextRange.empty,
    );
    _syncingToHtmlController = false;
  }

  QuillController _buildQuillController(
    String html, {
    int? fallbackSelectionOffset,
  }) {
    final document = _documentFromHtml(html);
    final requestedOffset = fallbackSelectionOffset ?? document.length - 1;
    final safeOffset = _clampSelectionOffset(
      requestedOffset,
      maxOffset: document.length - 1,
    );
    return QuillController(
      document: document,
      selection: TextSelection.collapsed(offset: safeOffset),
    );
  }

  Document _documentFromHtml(String html) {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      return Document()..insert(0, '\n');
    }
    try {
      final delta = HtmlToDelta().convert(trimmed);
      if (delta.isEmpty) {
        return Document()..insert(0, '\n');
      }
      return Document.fromDelta(delta);
    } catch (error) {
      debugPrint(
        '[TenantAdminRichTextEditor] Failed to parse HTML into delta: $error',
      );
      return Document()..insert(0, '\n');
    }
  }

  String _deltaToHtml(QuillController controller) {
    if (controller.document.toPlainText().trim().isEmpty) {
      return '';
    }
    final converter = QuillDeltaToHtmlConverter(
      controller.document.toDelta().toJson(),
      ConverterOptions.forEmail(),
    );
    final html = converter.convert().trim();
    if (_isBlankHtml(html)) {
      return '';
    }
    return html;
  }

  int _clampSelectionOffset(
    int value, {
    required int maxOffset,
  }) {
    if (maxOffset <= 0) {
      return 0;
    }
    if (value < 0) {
      return 0;
    }
    if (value > maxOffset) {
      return maxOffset;
    }
    return value;
  }

  bool _isBlankHtml(String html) {
    final compact = html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\u00a0', ' ')
        .trim();
    return compact.isEmpty;
  }

  String _normalizeHtml(String html) {
    return html.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.outlineVariant;
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return Localizations.override(
      context: context,
      locale: locale,
      delegates: FlutterQuillLocalizations.localizationsDelegates,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                QuillSimpleToolbar(
                  controller: _quillController,
                  config: QuillSimpleToolbarConfig(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: borderColor),
                      ),
                    ),
                    showFontFamily: false,
                    showFontSize: false,
                    showSmallButton: false,
                    showStrikeThrough: false,
                    showInlineCode: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showClearFormat: true,
                    showAlignmentButtons: false,
                    showHeaderStyle: true,
                    showListNumbers: true,
                    showListBullets: true,
                    showListCheck: false,
                    showCodeBlock: false,
                    showQuote: true,
                    showIndent: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showDirection: false,
                    showClipboardCut: false,
                    showClipboardCopy: false,
                    showClipboardPaste: false,
                  ),
                ),
                SizedBox(
                  height: widget.minHeight,
                  child: QuillEditor.basic(
                    controller: _quillController,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    config: QuillEditorConfig(
                      placeholder: widget.placeholder,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
