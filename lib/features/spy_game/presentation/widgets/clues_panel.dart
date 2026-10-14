import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../providers.dart';
import '../spy_strings.dart';
import 'feedback.dart';

/// The clue phase: whose turn it is, the clues of this round, and an input
/// for the current speaker. Clues of earlier rounds are collapsed below.
class CluesPanel extends ConsumerStatefulWidget {
  const CluesPanel({
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
  ConsumerState<CluesPanel> createState() => _CluesPanelState();
}

class _CluesPanelState extends ConsumerState<CluesPanel> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _nameOf(String uid) {
    for (final player in widget.players) {
      if (player.uid == uid) return player.displayName;
    }
    return SpyStrings.unknownPlayer;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(roomRepositoryProvider)
          .submitClue(roomId: widget.roomId, text: text);
      if (mounted) _controller.clear();
    } catch (error) {
      if (mounted) showRoomError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _clueRows(List<Clue> clues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final clue in clues)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${_nameOf(clue.authorUid)}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: clue.text),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final room = widget.room;
    final speakerUid = room.turnUid;
    final isMyTurn = speakerUid != null && speakerUid == widget.uid;
    final cluesAsync = ref.watch(cluesProvider(widget.roomId));

    final allClues = cluesAsync.asData?.value ?? const <Clue>[];
    final thisRound =
        allClues.where((clue) => clue.round == room.round).toList();
    final earlier = allClues.where((clue) => clue.round < room.round).toList();

    final rounds = <int>{for (final clue in earlier) clue.round}.toList()
      ..sort((a, b) => b.compareTo(a));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(SpyStrings.cluesTitle, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            if (speakerUid == null)
              Text(SpyStrings.noSpeaker)
            else if (isMyTurn) ...[
              Text(
                SpyStrings.yourTurnClue,
                style: textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                enabled: !_sending,
                maxLength: 40,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  labelText: SpyStrings.clueHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: SpyStrings.send,
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ),
              ),
            ] else
              Text(
                SpyStrings.turnOf(_nameOf(speakerUid)),
                style: textTheme.titleSmall,
              ),
            const Divider(height: 24),
            if (thisRound.isEmpty)
              Text(SpyStrings.noClues, style: textTheme.bodyMedium)
            else
              _clueRows(thisRound),
            if (rounds.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(SpyStrings.earlierRounds),
                children: [
                  for (final round in rounds) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        SpyStrings.roundNumber(round),
                        style: textTheme.labelLarge,
                      ),
                    ),
                    _clueRows(
                      earlier.where((clue) => clue.round == round).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
