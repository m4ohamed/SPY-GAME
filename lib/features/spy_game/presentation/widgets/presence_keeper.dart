import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/room_failure.dart';
import '../providers.dart';

/// An invisible widget that tells the server this player is still in the room.
/// It sends a heartbeat when it appears, every 15 seconds, and whenever the app
/// comes back to the foreground. It stops by itself once the room is gone or
/// the player is no longer in it.
class PresenceKeeper extends ConsumerStatefulWidget {
  const PresenceKeeper({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<PresenceKeeper> createState() => _PresenceKeeperState();
}

class _PresenceKeeperState extends ConsumerState<PresenceKeeper>
    with WidgetsBindingObserver {
  static const Duration _interval = Duration(seconds: 15);

  Timer? _timer;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _beat();
    _timer = Timer.periodic(_interval, (_) => _beat());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _beat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _beat() async {
    if (_stopped || !mounted) return;
    try {
      await ref.read(roomRepositoryProvider).heartbeat(widget.roomId);
    } on RoomException catch (error) {
      final gone = error.failure == RoomFailure.notInRoom ||
          error.failure == RoomFailure.roomNotFound;
      if (gone) {
        _stopped = true;
        _timer?.cancel();
      }
      // Any other failure, such as a short network drop, is retried by the
      // next beat.
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
