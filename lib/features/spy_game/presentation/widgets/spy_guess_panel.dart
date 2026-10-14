import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../providers.dart';
import '../spy_strings.dart';
import 'feedback.dart';

/// The caught spy's one chance to win by guessing the civilians' word.
class SpyGuessPanel extends ConsumerStatefulWidget {
  const SpyGuessPanel({
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
  ConsumerState<SpyGuessPanel> createState() => _SpyGuessPanelState();
}

class _SpyGuessPanelState extends ConsumerState<SpyGuessPanel> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(roomRepositoryProvider)
          .submitSpyGuess(roomId: widget.roomId, text: text);
    } catch (error) {
      if (mounted) showRoomError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final spyUid = widget.room.turnUid;
    final isSpy = spyUid != null && spyUid == widget.uid;

    var spyName = SpyStrings.unknownPlayer;
    for (final player in widget.players) {
      if (player.uid == spyUid) spyName = player.displayName;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isSpy
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SpyStrings.guessTitleSelf, style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    enabled: !_sending,
                    maxLength: 40,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      labelText: SpyStrings.guessHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: SpyStrings.send,
                        icon: const Icon(Icons.send),
                        onPressed: _sending ? null : _send,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                SpyStrings.guessWaiting(spyName),
                style: textTheme.titleMedium,
              ),
      ),
    );
  }
}
