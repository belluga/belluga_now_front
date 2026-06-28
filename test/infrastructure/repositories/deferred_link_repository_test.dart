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
        targetPath: '/invite?code=ABCD1234',
        storeChannel: 'play',
      ),
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      platformResolver: () => 'android',
      backend: backend,
    );

    final result = await repository.captureFirstOpenInviteCode();

    expect(result.status, DeferredLinkCaptureStatus.captured);
    expect(result.code, 'ABCD1234');
    expect(result.targetPath, '/invite?code=ABCD1234');
    expect(result.storeChannel, 'play');
    expect(result.platform, 'android');
    expect(backend.lastPlatform, 'android');
    expect(backend.lastResolverPayload, 'code=ABCD1234&store_channel=play');
    expect(backend.lastStoreChannel, 'play');
  });

  test(
    'captures target path when backend resolver returns non-invite path',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return <String, dynamic>{
              'install_referrer':
                  'target_path=%2Fagenda%2Fevento%2Fforro%3Foccurrence%3Docc-1&store_channel=play',
            };
          });

      final backend = _FakeDeferredLinkBackend(
        response: const DeferredLinkResolutionDto(
          status: 'captured',
          targetPath: '/agenda/evento/forro?occurrence=occ-1',
          storeChannel: 'play',
        ),
      );

      final repository = DeferredLinkRepository(
        channel: channel,
        platformResolver: () => 'android',
        backend: backend,
      );

      final result = await repository.captureFirstOpenInviteCode();

      expect(result.status, DeferredLinkCaptureStatus.captured);
      expect(result.code, isNull);
      expect(result.targetPath, '/agenda/evento/forro?occurrence=occ-1');
      expect(result.storeChannel, 'play');
      expect(result.platform, 'android');
    },
  );

  test(
    'returns notCaptured when backend resolver reports missing code',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return <String, dynamic>{'install_referrer': 'utm_source=play'};
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
        platformResolver: () => 'android',
        backend: backend,
      );

      final result = await repository.captureFirstOpenInviteCode();

      expect(result.status, DeferredLinkCaptureStatus.notCaptured);
      expect(result.failureReason, 'code_missing');
      expect(result.storeChannel, 'play');
      expect(result.platform, 'android');
    },
  );

  test(
    'returns notCaptured resolver_unavailable when backend call fails',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return <String, dynamic>{'install_referrer': 'utm_source=play'};
          });

      final backend = _FakeDeferredLinkBackend(
        response: const DeferredLinkResolutionDto(status: 'not_captured'),
        throwsOnResolve: true,
      );

      final repository = DeferredLinkRepository(
        channel: channel,
        platformResolver: () => 'android',
        backend: backend,
      );

      final result = await repository.captureFirstOpenInviteCode();

      expect(result.status, DeferredLinkCaptureStatus.notCaptured);
      expect(result.failureReason, 'resolver_unavailable');
      expect(result.storeChannel, 'play');
      expect(result.platform, 'android');
    },
  );

  test('skips Android capture when already attempted', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'deferred_link_capture_attempted': '1',
    });

    final backend = _FakeDeferredLinkBackend(
      response: const DeferredLinkResolutionDto(status: 'not_captured'),
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      platformResolver: () => 'android',
      backend: backend,
    );

    final result = await repository.captureFirstOpenInviteCode();

    expect(result.status, DeferredLinkCaptureStatus.skipped);
    expect(result.failureReason, 'already_attempted');
    expect(result.platform, 'android');
    expect(backend.callCount, 0);
  });

  test(
    'retries iOS when deferred payload is temporarily unavailable before finalizing',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      final backend = _FakeDeferredLinkBackend(
        response: const DeferredLinkResolutionDto(status: 'not_captured'),
      );

      final repository = DeferredLinkRepository(
        channel: channel,
        platformResolver: () => 'ios',
        backend: backend,
      );

      final firstResult = await repository.captureFirstOpenInviteCode();
      final secondResult = await repository.captureFirstOpenInviteCode();
      final thirdResult = await repository.captureFirstOpenInviteCode();
      final fourthResult = await repository.captureFirstOpenInviteCode();

      expect(firstResult.status, DeferredLinkCaptureStatus.notCaptured);
      expect(firstResult.failureReason, 'referrer_unavailable');
      expect(secondResult.status, DeferredLinkCaptureStatus.notCaptured);
      expect(secondResult.failureReason, 'referrer_unavailable');
      expect(thirdResult.status, DeferredLinkCaptureStatus.notCaptured);
      expect(thirdResult.failureReason, 'referrer_unavailable');
      expect(fourthResult.status, DeferredLinkCaptureStatus.skipped);
      expect(fourthResult.failureReason, 'already_attempted');
      expect(backend.callCount, 0);
    },
  );

  test('continues capture when storage markers are unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return <String, dynamic>{
            'install_referrer': 'code=ABCD1234&store_channel=play',
          };
        });

    final backend = _FakeDeferredLinkBackend(
      response: const DeferredLinkResolutionDto(
        status: 'captured',
        code: 'ABCD1234',
        targetPath: '/invite?code=ABCD1234',
        storeChannel: 'play',
      ),
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      platformResolver: () => 'android',
      backend: backend,
      storage: const _ThrowingSecureStorage(),
    );

    final result = await repository.captureFirstOpenInviteCode();

    expect(result.status, DeferredLinkCaptureStatus.captured);
    expect(result.targetPath, '/invite?code=ABCD1234');
    expect(result.platform, 'android');
    expect(backend.callCount, 1);
  });

  test('captures iOS deferred payload from pasteboard transport', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getDeferredLinkPasteboardPayload');
          return <String, dynamic>{
            'resolver_payload': 'target_path=%2Fprofile&store_channel=web_gate',
          };
        });

    final backend = _FakeDeferredLinkBackend(
      response: const DeferredLinkResolutionDto(
        status: 'captured',
        targetPath: '/profile',
        storeChannel: 'web_gate',
      ),
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      platformResolver: () => 'ios',
      backend: backend,
    );

    final result = await repository.captureFirstOpenInviteCode();

    expect(result.status, DeferredLinkCaptureStatus.captured);
    expect(result.targetPath, '/profile');
    expect(result.storeChannel, 'web_gate');
    expect(result.platform, 'ios');
    expect(backend.lastPlatform, 'ios');
    expect(
      backend.lastResolverPayload,
      'target_path=%2Fprofile&store_channel=web_gate',
    );
  });

  test(
    'retries iOS resolver failures before finalizing the deferred capture path',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getDeferredLinkPasteboardPayload');
            return <String, dynamic>{
              'resolver_payload':
                  'target_path=%2Fprofile&store_channel=web_gate',
            };
          });

      final backend = _FakeDeferredLinkBackend(
        response: const DeferredLinkResolutionDto(
          status: 'captured',
          targetPath: '/profile',
          storeChannel: 'web_gate',
        ),
        throwCountBeforeSuccess: 1,
      );

      final repository = DeferredLinkRepository(
        channel: channel,
        platformResolver: () => 'ios',
        backend: backend,
      );

      final firstResult = await repository.captureFirstOpenInviteCode();
      final secondResult = await repository.captureFirstOpenInviteCode();
      final thirdResult = await repository.captureFirstOpenInviteCode();

      expect(firstResult.status, DeferredLinkCaptureStatus.notCaptured);
      expect(firstResult.failureReason, 'resolver_unavailable');
      expect(secondResult.status, DeferredLinkCaptureStatus.captured);
      expect(secondResult.targetPath, '/profile');
      expect(thirdResult.status, DeferredLinkCaptureStatus.skipped);
      expect(thirdResult.failureReason, 'already_attempted');
      expect(backend.callCount, 2);
    },
  );

  test('finalizes iOS after terminal resolver outcome', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getDeferredLinkPasteboardPayload');
          return <String, dynamic>{'resolver_payload': 'utm_source=web_gate'};
        });

    final backend = _FakeDeferredLinkBackend(
      response: const DeferredLinkResolutionDto(
        status: 'not_captured',
        storeChannel: 'web_gate',
        failureReason: 'code_missing',
      ),
    );

    final repository = DeferredLinkRepository(
      channel: channel,
      platformResolver: () => 'ios',
      backend: backend,
    );

    final firstResult = await repository.captureFirstOpenInviteCode();
    final secondResult = await repository.captureFirstOpenInviteCode();

    expect(firstResult.status, DeferredLinkCaptureStatus.notCaptured);
    expect(firstResult.failureReason, 'code_missing');
    expect(secondResult.status, DeferredLinkCaptureStatus.skipped);
    expect(secondResult.failureReason, 'already_attempted');
    expect(backend.callCount, 1);
  });
}

class _FakeDeferredLinkBackend implements DeferredLinkBackendContract {
  _FakeDeferredLinkBackend({
    required this.response,
    this.throwsOnResolve = false,
    this.throwCountBeforeSuccess = 0,
  });

  final DeferredLinkResolutionDto response;
  final bool throwsOnResolve;
  final int throwCountBeforeSuccess;

  int callCount = 0;
  String? lastPlatform;
  String? lastResolverPayload;
  String? lastStoreChannel;

  @override
  Future<DeferredLinkResolutionDto> resolveDeferredLink({
    required String platform,
    String? resolverPayload,
    String? storeChannel,
  }) async {
    callCount += 1;
    lastPlatform = platform;
    lastResolverPayload = resolverPayload;
    lastStoreChannel = storeChannel;

    if (throwsOnResolve || callCount <= throwCountBeforeSuccess) {
      throw Exception('resolver unavailable');
    }

    return response;
  }
}

class _ThrowingSecureStorage extends FlutterSecureStorage {
  const _ThrowingSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) {
    throw StateError('secure storage read failed');
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) {
    throw StateError('secure storage write failed');
  }
}
