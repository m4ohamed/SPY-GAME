import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../../domain/phase_token.dart';
import '../../domain/room_failure.dart';
import '../providers.dart';

/// An invisible widget that keeps the game moving. When the current phase's
/// timer ends it asks the server to advance the game. Every client runs one;
/// the host calls right away and the others wait a short random time, and the
/// server ignores whichever calls arrive late or too early.
class PhaseTicker extends ConsumerStatefulWidget {
  const PhaseTicker({required this.room, super.key});

  final Room room;

  @override
  ConsumerState<PhaseTicker> createState() => _PhaseTickerState();
}

class _PhaseTickerState extends ConsumerState<PhaseTicker> {
  static const Duration _minRetry = Duration(milliseconds: 500);
  static const Duration _defaultRetry = Duration(seconds: 2);

  final Random _random = Random();
  Timer? _timer;
  String? _armedToken;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(PhaseTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    final room = widget.room;
    final token = phaseToken(room);
    if (token == _armedToken) return;
    _timer?.cancel();
    _armedToken = token;

    final endsAt = room.phaseEndsAt;
    if (endsAt == null) return;

    final repository = ref.read(roomRepositoryProvider);
    final isHost = repository.currentUid == room.hostUid;
    final jitter = isHost
        ? Duration.zero
        : Duration(milliseconds: 400 + _random.nextInt(1600));
    final untilEnd = endsAt.difference(repository.serverNow());
    _schedule(token, (untilEnd.isNegative ? Duration.zero : untilEnd) + jitter);
  }

  void _schedule(String token, Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () => _fire(token));
  }

  Future<void> _fire(String token) async {
    if (!mounted || phaseToken(widget.room) != token) return;

    var retry = _defaultRetry;
    try {
      final result = await ref.read(roomRepositoryProvider).tick(widget.room);
      // When the call advanced the game, the room stream delivers the new step
      // and didUpdateWidget arms the next timer.
      if (result.advanced) return;
      final hint = result.retryAfter;
      if (hint != null) {
        retry = hint > _minRetry ? hint : _minRetry;
      }
    } on RoomException catch (error) {
      if (error.failure == RoomFailure.notInRoom) return;
    }

    if (!mounted || phaseToken(widget.room) != token) return;
    _schedule(token, retry);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A mm:ss countdown to [endsAt], using the server's clock.
class PhaseCountdown extends ConsumerStatefulWidget {
  const PhaseCountdown({required this.endsAt, super.key});

  final DateTime endsAt;

  @override
  ConsumerState<PhaseCountdown> createState() => _PhaseCountdownState();
}

class _PhaseCountdownState extends ConsumerState<PhaseCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.read(roomRepositoryProvider).serverNow();
    var remaining = widget.endsAt.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;

    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final urgent = remaining.inSeconds <= 5;
    final theme = Theme.of(context);

    return Text(
      '$minutes:$secs',
      textDirection: TextDirection.ltr,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: urgent ? theme.colorScheme.error : null,
      ),
    );
  }
}
