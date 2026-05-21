import 'package:firebase_messaging/firebase_messaging.dart';

abstract class InvitePushTapSource {
  const InvitePushTapSource();

  Future<RemoteMessage?> getInitialMessage();

  Stream<RemoteMessage> get onMessageOpenedApp;
}

const InvitePushTapSource kFirebaseInvitePushTapSource =
    _FirebaseInvitePushTapSource();
const InvitePushTapSource kNoopInvitePushTapSource = _NoopInvitePushTapSource();

class _FirebaseInvitePushTapSource implements InvitePushTapSource {
  const _FirebaseInvitePushTapSource();

  @override
  Future<RemoteMessage?> getInitialMessage() {
    return FirebaseMessaging.instance.getInitialMessage();
  }

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}

class _NoopInvitePushTapSource implements InvitePushTapSource {
  const _NoopInvitePushTapSource();

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      const Stream<RemoteMessage>.empty();
}
