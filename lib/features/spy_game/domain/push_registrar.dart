/// Gets this device ready for push notifications and reports its OneSignal
/// subscription id, which the server uses to notify the player.
abstract interface class PushRegistrar {
  /// Asks for notification permission (the system shows its prompt only once)
  /// and returns this device's subscription id, or null when there is none
  /// yet, for example because permission was denied.
  Future<String?> prepare();

  /// Calls [onChanged] whenever the subscription id appears or changes.
  /// Returns a function that stops listening.
  void Function() listen(void Function(String id) onChanged);
}
