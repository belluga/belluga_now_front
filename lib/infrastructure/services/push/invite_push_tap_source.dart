import 'package:firebase_messaging/firebase_messaging.dart';

abstract class InvitePushTapSource {
  const InvitePushTapSource();

  Future<RemoteMessage?> getInitialMessage();

  Stream<RemoteMessage> get onMessageOpenedApp;
}

class FirebaseInvitePushTapSource implements InvitePushTapSource {
  const FirebaseInvitePushTapSource();

  @override
  Future<RemoteMessage?> getInitialMessage() {
    return FirebaseMessaging.instance.getInitialMessage();
  }

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}

class NoopInvitePushTapSource implements InvitePushTapSource {
  const NoopInvitePushTapSource();

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      const Stream<RemoteMessage>.empty();
}
