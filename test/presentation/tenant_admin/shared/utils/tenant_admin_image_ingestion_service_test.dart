import 'dart:async';
import 'dart:io';

import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final fallbackTempDir =
      Directory.systemTemp.createTempSync('tenant-admin-test');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return fallbackTempDir.path;
      }
      return null;
    });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (fallbackTempDir.existsSync()) {
      fallbackTempDir.deleteSync(recursive: true);
    }
  });

  test('prepareXFile normalizes avatar to 1:1 and max 1024', () async {
    final service = TenantAdminImageIngestionService();
    final source =
        await _writeImage(width: 1600, height: 900, name: 'avatar_source.png');

    final output = await service.prepareXFile(
      source,
      slot: TenantAdminImageSlot.avatar,
    );

    final bytes = await output.readAsBytes();
    final decoded = img.decodeImage(bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, decoded.height);
    expect(decoded.width, lessThanOrEqualTo(1024));
    expect(decoded.height, lessThanOrEqualTo(1024));
  });

  test('prepareXFile normalizes cover to 16:9 and max 1920x1080', () async {
    final service = TenantAdminImageIngestionService();
    final source =
        await _writeImage(width: 1200, height: 1800, name: 'cover_source.png');

    final output = await service.prepareXFile(
      source,
      slot: TenantAdminImageSlot.cover,
    );

    final bytes = await output.readAsBytes();
    final decoded = img.decodeImage(bytes);
    expect(decoded, isNotNull);
    final ratio = decoded!.width / decoded.height;
    expect((ratio - (16 / 9)).abs(), lessThan(0.02));
    expect(decoded.width, lessThanOrEqualTo(1920));
    expect(decoded.height, lessThanOrEqualTo(1080));
  });

  test('prepareXFile rejects source larger than 15MB before decode', () async {
    final service = TenantAdminImageIngestionService();
    final oversize = await _writeBytes(
      Uint8List(16 * 1024 * 1024),
      name: 'oversize.bin',
    );

    expect(
      () => service.prepareXFile(oversize, slot: TenantAdminImageSlot.cover),
      throwsA(
        isA<TenantAdminImageIngestionException>().having(
          (error) => error.message,
          'message',
          contains('Maximo 15MB'),
        ),
      ),
    );
  });

  test('importFromUrl returns fallback guidance when site blocks fetch',
      () async {
    final dio = Dio()..httpClientAdapter = _ThrowingHttpClientAdapter();
    final service = TenantAdminImageIngestionService(dio: dio);

    expect(
      () => service.importFromUrl(
        imageUrl: 'https://example.com/image.jpg',
        slot: TenantAdminImageSlot.avatar,
      ),
      throwsA(
        isA<TenantAdminImageIngestionException>().having(
          (error) => error.message,
          'message',
          contains('site nao permite importacao direta'),
        ),
      ),
    );
  });

  test('buildUpload returns jpeg payload', () async {
    final service = TenantAdminImageIngestionService();
    final source =
        await _writeImage(width: 900, height: 1200, name: 'upload.png');

    final upload = await service.buildUpload(
      source,
      slot: TenantAdminImageSlot.avatar,
    );

    expect(upload, isNotNull);
    expect(upload!.mimeType, 'image/jpeg');
    expect(upload.fileName, endsWith('.jpg'));
    expect(upload.bytes, isNotEmpty);
  });

  test('pickFromDevice applies avatar 1:1 crop pipeline', () async {
    final source =
        await _writeImage(width: 1600, height: 900, name: 'pick_avatar.png');
    final service = TenantAdminImageIngestionService(
      imagePicker: _FakeImagePicker(source),
    );

    final output = await service.pickFromDevice(
      slot: TenantAdminImageSlot.avatar,
    );

    expect(output, isNotNull);
    final decoded = img.decodeImage(await output!.readAsBytes());
    expect(decoded, isNotNull);
    expect(decoded!.width, decoded.height);
    expect(decoded.width, lessThanOrEqualTo(1024));
  });

  test('pickFromDevice applies cover 16:9 crop pipeline', () async {
    final source =
        await _writeImage(width: 1200, height: 1800, name: 'pick_cover.png');
    final service = TenantAdminImageIngestionService(
      imagePicker: _FakeImagePicker(source),
    );

    final output = await service.pickFromDevice(
      slot: TenantAdminImageSlot.cover,
    );

    expect(output, isNotNull);
    final decoded = img.decodeImage(await output!.readAsBytes());
    expect(decoded, isNotNull);
    final ratio = decoded!.width / decoded.height;
    expect((ratio - (16 / 9)).abs(), lessThan(0.02));
    expect(decoded.width, lessThanOrEqualTo(1920));
    expect(decoded.height, lessThanOrEqualTo(1080));
  });
}

Future<XFile> _writeImage({
  required int width,
  required int height,
  required String name,
}) async {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 45, 180));
  final bytes = Uint8List.fromList(img.encodePng(image));
  return _writeBytes(bytes, name: name);
}

Future<XFile> _writeBytes(Uint8List bytes, {required String name}) async {
  final dir = await Directory.systemTemp.createTemp('tenant-admin-ingestion');
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, name: name);
}

class _ThrowingHttpClientAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'blocked',
    );
  }
}

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this._nextFile);

  final XFile? _nextFile;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return _nextFile;
  }
}
