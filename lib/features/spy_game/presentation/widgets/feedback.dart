import 'package:flutter/material.dart';

import '../../domain/room_failure.dart';
import '../spy_strings.dart';

/// Shows the Arabic message for a failed room action as a snack bar.
void showRoomError(BuildContext context, Object error) {
  final failure = error is RoomException ? error.failure : RoomFailure.unknown;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(SpyStrings.failureMessage(failure))));
}
