import 'dart:convert';

import 'package:belluga_now/domain/repositories/deferred_link_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_local_state.dart';
import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_local_state_storage_contract.dart';
import 'package:belluga_now/infrastructure/repositories/deferred_link_repository.dart';
import 'package:belluga_now/infrastructure/dal/dto/deferred_link/deferred_link_resolution_dto.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_native_payload.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_native_source_contract.dart';
import 'package:crypto/crypto.dart';
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
      localStateStorage: _InMemoryDeferredLinkLocalStateStorage(),
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
        localStateStorage: _InMemoryDeferredLinkLocalStateStorage(),
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
        localStateStorage: _InMemoryDeferredLinkLocalStateStorage(),
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
        localStateStorage: _InMemoryDeferredLinkLocalStateStorage(),
      );

      final result = await repository.captureFirstOpenInviteCode();

      expect(result.status, DeferredLinkCaptureStatus.notCaptured);
      expect(result.failureReason, 'resolver_unavailable');
      expect(result.storeChannel, 'play');
      expect(result.platform, 'android');
    },
  );

  test(
    'skips Android capture when install-scoped state already attempted',
    () async {
      final localStateStorage = _InMemoryDeferredLinkLocalStateStorage(
        <String, String>{'deferred_link_capture_attempted': '1'},
      );

      final backend = _FakeDeferredLinkBackend(
        response: const DeferredLinkResolutionDto(status: 'not_captured'),
      );

      final repository = DeferredLinkRepository(
        channel: channel,
        platformResolver: () => 'android',
        backend: backend,
        localStateStorage: localStateStorage,
      );

      final result = await repository.captureFirstOpenInviteCode();

      expect(result.status, DeferredLinkCaptureStatus.skipped);
      expect(result.failureReason, 'already_attempted');
      expect(result.platform, 'android');
      expect(backend.callCount, 0);
    },
  );

  test(
    'retries iOS deferred payload reads inside the same call before finalizing',
    () async {
      final backend = _FakeDeferredLinkBackend(
        response: const DeferredLinkResolutionDto(
          status: 'captured',
          targetPath: '/profile',
          storeChannel: 'web_gate',
        ),
      );
      final nativeSource = _SequenceDeferredLinkNativeSource(
        responses: <DeferredLinkNativePayload?>[
          null,
          null,
          const DeferredLinkNativePayload(
            resolverPayload: 'target_path=%2Fprofile&store_channel=web_gate',
            storeChannel: 'web_gate',
          ),
        ],
      );
      final localStateStorage = _InMemoryDeferredLinkLocalStateStorage();

      final repository = DeferredLinkRepository(
        platformResolver: () => 'ios',
        backend: backend,
        iosRetryDelays: const <Duration>[Duration.zero, Duration.zero],
        nativeSource: nativeSource,
        localStateStorage: localStateStorage,
      );

      final firstResult = await repository.captureFirstOpenInviteCode();
      final secondResult = await repository.captureFirstOpenInviteCode();

      expect(firstResult.status, DeferredLinkCaptureStatus.captured);
      expect(firstResult.targetPath, '/profile');
      expect(secondResult.status, DeferredLinkCaptureStatus.skipped);
      expect(secondResult.failureReason, 'already_attempted');
      expect(nativeSource.callCount, 3);
      expect(backend.callCount, 1);
      expect(
        localStateStorage.valueFor('deferred_link_ios_capture_finalized'),
        '1',
      );
    },
  );

  test('continues capture when local state markers are unavailable', () async {
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
      localStateStorage: const _ThrowingDeferredLinkLocalStateStorage(),
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
      localStateStorage: _InMemoryDeferredLinkLocalStateStorage(),
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
    'retries iOS resolver failures inside the same call before finalizing',
    () async {
      final backend = _FakeDeferredLinkBackend(
        response: const DeferredLinkResolutionDto(
          status: 'captured',
          targetPath: '/profile',
          storeChannel: 'web_gate',
        ),
        throwCountBeforeSuccess: 1,
      );
      final nativeSource = _SequenceDeferredLinkNativeSource(
        responses: <DeferredLinkNativePayload?>[
          const DeferredLinkNativePayload(
            resolverPayload: 'target_path=%2Fprofile&store_channel=web_gate',
            storeChannel: 'web_gate',
          ),
        ],
      );
      final localStateStorage = _InMemoryDeferredLinkLocalStateStorage();

      final repository = DeferredLinkRepository(
        platformResolver: () => 'ios',
        backend: backend,
        iosRetryDelays: const <Duration>[Duration.zero, Duration.zero],
        nativeSource: nativeSource,
        localStateStorage: localStateStorage,
      );

      final firstResult = await repository.captureFirstOpenInviteCode();
      final secondResult = await repository.captureFirstOpenInviteCode();

      expect(firstResult.status, DeferredLinkCaptureStatus.captured);
      expect(firstResult.targetPath, '/profile');
      expect(secondResult.status, DeferredLinkCaptureStatus.skipped);
      expect(secondResult.failureReason, 'already_attempted');
      expect(backend.callCount, 2);
      expect(nativeSource.callCount, 2);
      expect(
        localStateStorage.valueFor('deferred_link_ios_capture_finalized'),
        '1',
      );
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
      localStateStorage: _InMemoryDeferredLinkLocalStateStorage(),
    );

    final firstResult = await repository.captureFirstOpenInviteCode();
    final secondResult = await repository.captureFirstOpenInviteCode();

    expect(firstResult.status, DeferredLinkCaptureStatus.notCaptured);
    expect(firstResult.failureReason, 'code_missing');
    expect(secondResult.status, DeferredLinkCaptureStatus.skipped);
    expect(secondResult.failureReason, 'already_attempted');
    expect(backend.callCount, 1);
  });

  test(
    'migrates Android attempted marker from legacy secure storage into install-scoped state',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'deferred_link_capture_attempted': '1',
      });
      final primaryStorage = _InMemoryDeferredLinkLocalStateStorage();

      final repository = DeferredLinkRepository(
        platformResolver: () => 'android',
        backend: _FakeDeferredLinkBackend(
          response: const DeferredLinkResolutionDto(status: 'not_captured'),
        ),
        localStateStorage: DeferredLinkLocalStateStorage(
          primaryStorage: primaryStorage,
          legacyStorage: const FlutterSecureStorage(),
        ),
      );

      final result = await repository.captureFirstOpenInviteCode();

      expect(result.status, DeferredLinkCaptureStatus.skipped);
      expect(result.failureReason, 'already_attempted');
      expect(primaryStorage.valueFor('deferred_link_capture_attempted'), '1');
      expect(
        await const FlutterSecureStorage().read(
          key: 'deferred_link_capture_attempted',
        ),
        isNull,
      );
    },
  );

  test(
    'migrates iOS finalized marker from legacy secure storage into install-scoped state',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'deferred_link_ios_capture_finalized': '1',
      });
      final primaryStorage = _InMemoryDeferredLinkLocalStateStorage();

      final repository = DeferredLinkRepository(
        platformResolver: () => 'ios',
        backend: _FakeDeferredLinkBackend(
          response: const DeferredLinkResolutionDto(status: 'not_captured'),
        ),
        localStateStorage: DeferredLinkLocalStateStorage(
          primaryStorage: primaryStorage,
          legacyStorage: const FlutterSecureStorage(),
        ),
      );

      final result = await repository.captureFirstOpenInviteCode();

      expect(result.status, DeferredLinkCaptureStatus.skipped);
      expect(result.failureReason, 'already_attempted');
      expect(
        primaryStorage.valueFor('deferred_link_ios_capture_finalized'),
        '1',
      );
      expect(
        await const FlutterSecureStorage().read(
          key: 'deferred_link_ios_capture_finalized',
        ),
        isNull,
      );
    },
  );

  test(
    'migrates consumed referrer hash from legacy secure storage and preserves dedupe',
    () async {
      const resolverPayload = 'target_path=%2Fprofile&store_channel=web_gate';
      final consumedHash = sha256
          .convert(utf8.encode(resolverPayload))
          .toString();
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'deferred_link_consumed_referrer_hash': consumedHash,
      });
      final primaryStorage = _InMemoryDeferredLinkLocalStateStorage();

      final repository = DeferredLinkRepository(
        platformResolver: () => 'ios',
        backend: _FakeDeferredLinkBackend(
          response: const DeferredLinkResolutionDto(
            status: 'captured',
            targetPath: '/profile',
            storeChannel: 'web_gate',
          ),
        ),
        nativeSource: _SequenceDeferredLinkNativeSource(
          responses: const <DeferredLinkNativePayload?>[
            DeferredLinkNativePayload(
              resolverPayload: resolverPayload,
              storeChannel: 'web_gate',
            ),
          ],
        ),
        localStateStorage: DeferredLinkLocalStateStorage(
          primaryStorage: primaryStorage,
          legacyStorage: const FlutterSecureStorage(),
        ),
      );

      final result = await repository.captureFirstOpenInviteCode();

      expect(result.status, DeferredLinkCaptureStatus.notCaptured);
      expect(result.failureReason, 'referrer_already_consumed');
      expect(
        primaryStorage.valueFor('deferred_link_consumed_referrer_hash'),
        consumedHash,
      );
      expect(
        await const FlutterSecureStorage().read(
          key: 'deferred_link_consumed_referrer_hash',
        ),
        isNull,
      );
    },
  );
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

class _SequenceDeferredLinkNativeSource
    implements DeferredLinkNativeSourceContract {
  _SequenceDeferredLinkNativeSource({required this.responses});

  final List<DeferredLinkNativePayload?> responses;

  int callCount = 0;

  @override
  Future<DeferredLinkNativePayload?> readDeferredPayload({
    required String platform,
  }) async {
    if (responses.isEmpty) {
      return null;
    }

    final index = callCount;
    callCount += 1;
    if (index >= responses.length) {
      return responses.last;
    }
    return responses[index];
  }
}

class _InMemoryDeferredLinkLocalStateStorage
    implements DeferredLinkLocalStateStorageContract {
  _InMemoryDeferredLinkLocalStateStorage([Map<String, String>? initialValues])
    : _values = Map<String, String>.from(
        initialValues ?? const <String, String>{},
      );

  final Map<String, String> _values;

  String? valueFor(String key) => _values[key];

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

class _ThrowingDeferredLinkLocalStateStorage
    implements DeferredLinkLocalStateStorageContract {
  const _ThrowingDeferredLinkLocalStateStorage();

  @override
  Future<String?> read(String key) {
    throw StateError('deferred link local state read failed');
  }

  @override
  Future<void> write(String key, String value) {
    throw StateError('deferred link local state write failed');
  }

  @override
  Future<void> delete(String key) {
    throw StateError('deferred link local state delete failed');
  }
}
