import 'package:flutter/material.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../spy_strings.dart';

/// The end of the game: who won and why, both words, who the spies were, and
/// the tally of the deciding vote. All of it comes from `room.reveal`, which
/// the server writes only when the game is over.
class ResultPanel extends StatelessWidget {
  const ResultPanel({required this.reveal, required this.players, super.key});

  final GameReveal reveal;
  final List<Player> players;

  String _nameOf(String uid) {
    for (final player in players) {
      if (player.uid == uid) return player.displayName;
    }
    return SpyStrings.unknownPlayer;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final spyWord = reveal.spyWord;
    final guess = reveal.spyGuess;
    final tally = reveal.tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final spyNames = reveal.spyUids.map(_nameOf).join('، ');

    Widget line(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: textTheme.titleSmall),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                SpyStrings.winnerText(reveal.winner, reveal.spyUids.length),
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(child: Text(SpyStrings.endReason(reveal.reason))),
            const Divider(height: 24),
            line(SpyStrings.civilianWordLabel, reveal.civilianWord),
            if (spyWord != null) line(SpyStrings.spyWordLabel, spyWord),
            line(SpyStrings.spiesLabel, spyNames),
            if (guess != null) line(SpyStrings.guessLabel, guess),
            if (tally.isNotEmpty) ...[
              const Divider(height: 24),
              Text(SpyStrings.tallyTitle, style: textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final entry in tally)
                line(_nameOf(entry.key), SpyStrings.votesCount(entry.value)),
            ],
          ],
        ),
      ),
    );
  }
}
