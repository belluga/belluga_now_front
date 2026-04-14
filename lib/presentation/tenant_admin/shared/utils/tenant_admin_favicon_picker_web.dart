import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

class TenantAdminPickedBinaryFile {
  const TenantAdminPickedBinaryFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String? mimeType;
}

Future<TenantAdminPickedBinaryFile?> pickTenantAdminFaviconFile() {
  final completer = Completer<TenantAdminPickedBinaryFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.ico,image/x-icon,image/vnd.microsoft.icon'
    ..multiple = false;

  var selectionHandled = false;

  late final web.EventListener changeListener;
  late final web.EventListener focusListener;

  void cleanup() {
    input.removeEventListener('change', changeListener);
    web.window.removeEventListener('focus', focusListener);
  }

  changeListener = ((web.Event _) {
    selectionHandled = true;
    final file = input.files?.item(0);
    if (file == null) {
      cleanup();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }

    () async {
      try {
        final buffer = await file.arrayBuffer().toDart;
        cleanup();
        if (!completer.isCompleted) {
          completer.complete(
            TenantAdminPickedBinaryFile(
              name: file.name,
              bytes: Uint8List.view(buffer.toDart),
              mimeType: file.type.isEmpty ? null : file.type,
            ),
          );
        }
      } catch (_) {
        cleanup();
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Nao foi possivel ler o favicon selecionado.'),
          );
        }
      }
    }();
  }).toJS;

  focusListener = ((web.Event _) {
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!selectionHandled && !completer.isCompleted) {
        cleanup();
        completer.complete(null);
      }
    });
  }).toJS;

  input.addEventListener('change', changeListener);
  web.window.addEventListener(
    'focus',
    focusListener,
    web.AddEventListenerOptions(once: true),
  );
  input.click();

  return completer.future;
}
