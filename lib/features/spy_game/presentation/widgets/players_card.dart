import 'package:flutter/material.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../spy_strings.dart';

/// The list of players in a room, with host, connection, and elimination
/// markers. Shows a kick button next to other players when [onKick] is set.
class PlayersCard extends StatelessWidget {
  const PlayersCard({
    required this.players,
    required this.hostUid,
    required this.currentUid,
    this.onKick,
    super.key,
  });

  final List<Player> players;
  final String hostUid;
  final String? currentUid;

  /// Null when the current user cannot kick (not the host, busy, or in game).
  final ValueChanged<Player>? onKick;

  static String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first);
  }

  Widget _tile(Player player) {
    final parts = <String>[
      if (player.uid == hostUid) SpyStrings.host,
      if (!player.connected) SpyStrings.disconnected,
      if (!player.alive) SpyStrings.eliminated,
    ];
    final kick = onKick;
    final isYou = player.uid == currentUid;

    return ListTile(
      leading: CircleAvatar(child: Text(_initial(player.displayName))),
      title: Text(
        isYou
            ? '${player.displayName} (${SpyStrings.you})'
            : player.displayName,
        style: player.alive
            ? null
            : const TextStyle(decoration: TextDecoration.lineThrough),
      ),
      subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
      trailing: kick != null && !isYou
          ? IconButton(
              tooltip: SpyStrings.kick,
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: () => kick(player),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${SpyStrings.playersTitle} (${players.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final player in players) _tile(player),
          ],
        ),
      ),
    );
  }
}
