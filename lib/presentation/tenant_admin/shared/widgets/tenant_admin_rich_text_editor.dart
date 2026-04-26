import 'dart:async';
import 'dart:convert';

import 'package:belluga_now/application/observability/sentry_error_reporter.dart';
import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class TenantAdminRichTextEditor extends StatefulWidget {
  const TenantAdminRichTextEditor({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.minHeight = 180,
    this.errorText,
    this.maxContentBytes,
    this.warningThreshold = 0.90,
  });

  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final double minHeight;
  final String? errorText;
  final int? maxContentBytes;
  final double warningThreshold;

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
    if (_syncHtmlControllerFromDocument()) {
      _replaceQuillController(
        _buildQuillController(widget.controller.text),
      );
    }
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
    if (_syncHtmlControllerFromDocument()) {
      _replaceQuillController(
        _buildQuillController(widget.controller.text),
      );
    }
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
    _documentChangesSubscription = _quillController.document.changes.listen((
      _,
    ) {
      if (_syncHtmlControllerFromDocument()) {
        _rebuildCanonicalDocument(
          selectionOffset: _quillController.selection.baseOffset,
        );
        _syncHtmlControllerFromDocument();
      }
      _requestRebuild();
    });
  }

  void _replaceQuillController(QuillController nextController) {
    _documentChangesSubscription?.cancel();
    _quillController = nextController;
    _bindDocumentChanges();
    _requestRebuild();
  }

  void _requestRebuild() {
    if (!mounted) {
      return;
    }
    (context as Element).markNeedsBuild();
  }

  void _handleExternalHtmlChange() {
    if (_syncingToHtmlController) {
      return;
    }
    final targetHtml = widget.controller.text;
    if (_normalizeHtml(targetHtml) ==
        _normalizeHtml(_deltaToHtml(_quillController))) {
      return;
    }
    _syncingFromHtmlController = true;
    _replaceQuillController(
      _buildQuillController(
        targetHtml,
        fallbackSelectionOffset: _quillController.selection.baseOffset,
      ),
    );
    _rebuildCanonicalDocument(
      selectionOffset: _quillController.selection.baseOffset,
    );
    _syncingFromHtmlController = false;
    _syncHtmlControllerFromDocument();
  }

  bool _syncHtmlControllerFromDocument() {
    if (_syncingFromHtmlController) {
      return false;
    }
    final html = _deltaToHtml(_quillController);
    if (_normalizeHtml(widget.controller.text) == _normalizeHtml(html)) {
      return false;
    }
    _syncingToHtmlController = true;
    widget.controller.value = widget.controller.value.copyWith(
      text: html,
      selection: TextSelection.collapsed(offset: html.length),
      composing: TextRange.empty,
    );
    _syncingToHtmlController = false;
    return true;
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
      final delta = HtmlToDelta().convert(
        SafeRichHtml.sanitizeMarkupFragment(trimmed),
      );
      if (delta.isEmpty) {
        return Document()..insert(0, '\n');
      }
      final canonicalDelta = _canonicalizeDelta(delta);
      if (_deltaJson(delta) == _deltaJson(canonicalDelta)) {
        return Document.fromDelta(delta);
      }
      return Document.fromDelta(canonicalDelta);
    } catch (error, stackTrace) {
      unawaited(
        SentryErrorReporter.captureRecoverable(
          origin: 'tenant_admin.rich_text_editor.html_to_delta',
          error: error,
          stackTrace: stackTrace,
        ),
      );
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
    final canonicalDelta = _canonicalizeDelta(controller.document.toDelta());
    final converter = QuillDeltaToHtmlConverter(
      canonicalDelta.toJson(),
      ConverterOptions.forEmail(),
    );
    final html = converter.convert().trim();
    if (SafeRichHtml.isEffectivelyEmpty(html)) {
      return '';
    }
    return SafeRichHtml.sanitizeMarkupFragment(html);
  }

  void _rebuildCanonicalDocument({int? selectionOffset}) {
    final currentDelta = _quillController.document.toDelta();
    final canonicalDelta = _canonicalizeDelta(currentDelta);
    if (_deltaJson(currentDelta) == _deltaJson(canonicalDelta)) {
      return;
    }

    final canonicalDocument = canonicalDelta.isEmpty
        ? (Document()..insert(0, '\n'))
        : Document.fromDelta(canonicalDelta);
    final requestedOffset =
        selectionOffset ?? _quillController.selection.baseOffset;
    final safeOffset = _clampSelectionOffset(
      requestedOffset,
      maxOffset: canonicalDocument.length - 1,
    );

    _replaceQuillController(
      QuillController(
        document: canonicalDocument,
        selection: TextSelection.collapsed(offset: safeOffset),
      ),
    );
  }

  Delta _canonicalizeDelta(Delta delta) {
    final canonical = Delta();
    for (final op in delta.toJson()) {
      final insert = op['insert'];
      if (insert is! String) {
        continue;
      }
      final attributes = _canonicalizeAttributes(
        op['attributes'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(op['attributes'] as Map)
            : null,
        insert,
      );
      canonical.insert(insert, attributes);
    }

    return canonical;
  }

  Map<String, dynamic>? _canonicalizeAttributes(
    Map<String, dynamic>? attributes,
    String insert,
  ) {
    if (attributes == null || attributes.isEmpty) {
      return null;
    }

    final canonical = <String, dynamic>{};
    if (insert == '\n') {
      final header = _normalizeHeader(attributes['header']);
      if (header != null) {
        canonical['header'] = header;
      }

      final list = attributes['list'];
      if (list == 'ordered' || list == 'bullet') {
        canonical['list'] = list;
      }

      if (attributes['blockquote'] == true) {
        canonical['blockquote'] = true;
      }

      return canonical.isEmpty ? null : canonical;
    }

    if (attributes['bold'] == true) {
      canonical['bold'] = true;
    }
    if (attributes['italic'] == true) {
      canonical['italic'] = true;
    }
    if (attributes['strike'] == true) {
      canonical['strike'] = true;
    }

    return canonical.isEmpty ? null : canonical;
  }

  num? _normalizeHeader(dynamic value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    if (parsed == null || parsed < 1 || parsed > 6) {
      return null;
    }
    return parsed;
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

  String _deltaJson(Delta delta) => jsonEncode(delta.toJson());

  String _normalizeHtml(String html) {
    return html.trim();
  }

  int get _currentContentBytes => utf8.encode(widget.controller.text).length;

  String _formatByteCount(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kilobytes = bytes / 1024;
    final hasFraction = kilobytes.truncateToDouble() != kilobytes;
    return hasFraction
        ? '${kilobytes.toStringAsFixed(1)} KB'
        : '${kilobytes.toStringAsFixed(0)} KB';
  }

  String _formatPercentage(double fraction) {
    return '${(fraction * 100).round()}%';
  }

  bool get _shouldShowLimitWarning {
    final maxBytes = widget.maxContentBytes;
    if (maxBytes == null || maxBytes <= 0) {
      return false;
    }
    return _currentContentBytes >= maxBytes * widget.warningThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = widget.errorText == null || widget.errorText!.isEmpty
        ? colorScheme.outlineVariant
        : colorScheme.error;
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    final maxContentBytes = widget.maxContentBytes;
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
                    showUnderLineButton: false,
                    showStrikeThrough: true,
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
                    showLink: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showDirection: false,
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
          if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
          ],
          if (maxContentBytes != null && maxContentBytes > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Limite: ${_formatByteCount(maxContentBytes)} por campo. '
              'O backend valida o envio final.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatByteCount(_currentContentBytes)} / '
              '${_formatByteCount(maxContentBytes)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _shouldShowLimitWarning
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (_shouldShowLimitWarning) ...[
              const SizedBox(height: 4),
              Text(
                'Este campo já passou de '
                '${_formatPercentage(widget.warningThreshold)} do limite de '
                '${_formatByteCount(maxContentBytes)}.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
