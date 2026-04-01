import 'package:belluga_now/domain/repositories/deferred_link_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/deferred_link_repository.dart';
import 'package:belluga_now/infrastructure/dal/dto/deferred_link/deferred_link_resolution_dto.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_backend_contract.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'com.belluga_now/deferred_link';
  const channel = MethodChannel(channelName);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('captures code when backend resolver returns captured', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getInstallReferrer');
      return <String, dynamic>{
        'install_referrer': 'code=ABCD1234&store_channel=play',
      };
    });

    final backend = _FakeDeferredLinkBackend(
      response: const DeferredLinkResolutionDto(
        status: 'captured',
        code: 'ABCD1234',
        storeChannel: 'play',
      ),
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      isAndroid: () => true,
      backend: backend,
    );

    final result = await repository.captureFirstOpenInviteCode();

    expect(result.status, DeferredLinkCaptureStatus.captured);
    expect(result.code, 'ABCD1234');
    expect(result.storeChannel, 'play');
    expect(backend.lastPlatform, 'android');
    expect(backend.lastInstallReferrer, 'code=ABCD1234&store_channel=play');
    expect(backend.lastStoreChannel, 'play');
  });

  test('returns notCaptured when backend resolver reports missing code',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return <String, dynamic>{
        'install_referrer': 'utm_source=play',
      };
    });

    final backend = _FakeDeferredLinkBackend(
      response: const DeferredLinkResolutionDto(
        status: 'not_captured',
        storeChannel: 'play',
        failureReason: 'code_missing',
      ),
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      isAndroid: () => true,
      backend: backend,
    );

    final result = await repository.captureFirstOpenInviteCode();

    expect(result.status, DeferredLinkCaptureStatus.notCaptured);
    expect(result.failureReason, 'code_missing');
    expect(result.storeChannel, 'play');
  });

  test('returns notCaptured resolver_unavailable when backend call fails',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return <String, dynamic>{
        'install_referrer': 'utm_source=play',
      };
    });

    final backend = _FakeDeferredLinkBackend(
      response: const DeferredLinkResolutionDto(status: 'not_captured'),
      throwsOnResolve: true,
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      isAndroid: () => true,
      backend: backend,
    );

    final result = await repository.captureFirstOpenInviteCode();

    expect(result.status, DeferredLinkCaptureStatus.notCaptured);
    expect(result.failureReason, 'resolver_unavailable');
    expect(result.storeChannel, 'play');
  });

  test('skips when capture already attempted', () async {
    FlutterSecureStorage.setMockInitialValues(
      <String, String>{'deferred_link_capture_attempted': '1'},
    );

    final backend = _FakeDeferredLinkBackend(
      response: const DeferredLinkResolutionDto(status: 'not_captured'),
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      isAndroid: () => true,
      backend: backend,
    );

    final result = await repository.captureFirstOpenInviteCode();

    expect(result.status, DeferredLinkCaptureStatus.skipped);
    expect(result.failureReason, 'already_attempted');
    expect(backend.callCount, 0);
  });
}

class _FakeDeferredLinkBackend implements DeferredLinkBackendContract {
  _FakeDeferredLinkBackend({
    required this.response,
    this.throwsOnResolve = false,
  });

  final DeferredLinkResolutionDto response;
  final bool throwsOnResolve;

  int callCount = 0;
  String? lastPlatform;
  String? lastInstallReferrer;
  String? lastStoreChannel;

  @override
  Future<DeferredLinkResolutionDto> resolveDeferredLink({
    required String platform,
    String? installReferrer,
    String? storeChannel,
  }) async {
    callCount += 1;
    lastPlatform = platform;
    lastInstallReferrer = installReferrer;
    lastStoreChannel = storeChannel;

    if (throwsOnResolve) {
      throw Exception('resolver unavailable');
    }

    return response;
  }
}
