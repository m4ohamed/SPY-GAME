import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../providers.dart';
import '../spy_strings.dart';
import 'feedback.dart';

/// The vote phase: pick who you think the spy is. After a tie, only the tied
/// players can receive votes. Individual votes stay hidden until the end.
class VotePanel extends ConsumerStatefulWidget {
  const VotePanel({
    required this.roomId,
    required this.room,
    required this.players,
    required this.uid,
    super.key,
  });

  final String roomId;
  final Room room;
  final List<Player> players;
  final String? uid;

  @override
  ConsumerState<VotePanel> createState() => _VotePanelState();
}

class _VotePanelState extends ConsumerState<VotePanel> {
  bool _sending = false;

  Future<void> _vote(Player target) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(roomRepositoryProvider)
          .castVote(roomId: widget.roomId, targetUid: target.uid);
    } catch (error) {
      if (mounted) showRoomError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final room = widget.room;

    Player? me;
    for (final player in widget.players) {
      if (player.uid == widget.uid) me = player;
    }
    final voters =
        widget.players.where((p) => p.alive && p.connected).toList();
    final candidates = widget.players.where((player) {
      final allowed = room.voteCandidateUids.isEmpty ||
          room.voteCandidateUids.contains(player.uid);
      return player.alive && player.uid != widget.uid && allowed;
    }).toList();

    final Widget body;
    if (me == null || !me.alive) {
      body = Text(SpyStrings.outOfGame);
    } else if (me.hasVoted) {
      body = Text(
        SpyStrings.voteRecorded,
        style: textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      body = Column(
        children: [
          for (final player in candidates)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _sending ? null : () => _vote(player),
                  child: Text(player.displayName),
                ),
              ),
            ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.isRevote ? SpyStrings.revoteTitle : SpyStrings.voteTitle,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(SpyStrings.votesProgress(room.voteCount, voters.length)),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}
