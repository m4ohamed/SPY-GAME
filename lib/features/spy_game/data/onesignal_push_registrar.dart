import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../domain/push_registrar.dart';

/// [PushRegistrar] backed by the OneSignal Flutter SDK (version 5).
///
/// The app must have called `OneSignal.initialize(appId)` at startup, as in
/// any other app that uses OneSignal. This class never calls `OneSignal.login`,
/// so it does not change how the app identifies users to OneSignal.
class OneSignalPushRegistrar implements PushRegistrar {
  @override
  Future<String?> prepare() async {
    await OneSignal.Notifications.requestPermission(false);
    return OneSignal.User.pushSubscription.id;
  }

  @override
  void Function() listen(void Function(String id) onChanged) {
    void observer(OSPushSubscriptionChangedState state) {
      final id = state.current.id;
      if (id != null) onChanged(id);
    }

    OneSignal.User.pushSubscription.addObserver(observer);
    return () => OneSignal.User.pushSubscription.removeObserver(observer);
  }
}
