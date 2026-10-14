import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../providers.dart';
import '../spy_strings.dart';

/// Shows the player's own secret only while a finger is held on the card, so
/// a neighbour cannot glance at the screen. It reads `secrets/{uid}`, which
/// only this player is allowed to read.
class RoleCard extends ConsumerStatefulWidget {
  const RoleCard({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends ConsumerState<RoleCard> {
  bool _revealed = false;

  void _setRevealed(bool value) {
    if (_revealed != value) {
      setState(() => _revealed = value);
    }
  }

  Widget _hidden(TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.visibility_off_outlined, size: 40),
        const SizedBox(height: 12),
        Text(
          SpyStrings.holdToReveal,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _secretContent(PlayerSecret secret, TextTheme textTheme) {
    final role = secret.role;
    final word = secret.word;
    final colorScheme = Theme.of(context).colorScheme;

    final roleLine = switch (role) {
      PlayerRole.spy => SpyStrings.youAreSpy,
      PlayerRole.civilian => SpyStrings.youAreCivilian,
      null => null,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (roleLine != null)
          Text(
            roleLine,
            style: textTheme.titleLarge?.copyWith(
              color: role == PlayerRole.spy ? colorScheme.error : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (word != null) ...[
          const SizedBox(height: 8),
          Text(SpyStrings.yourWord, style: textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            word,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else if (role == PlayerRole.spy) ...[
          const SizedBox(height: 8),
          Text(
            SpyStrings.spyHint,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ] else
          Text(SpyStrings.noSecret, style: textTheme.bodyLarge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secretAsync = ref.watch(mySecretProvider(widget.roomId));

    final Widget content;
    if (!_revealed) {
      content = _hidden(textTheme);
    } else {
      content = secretAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) =>
            Text(SpyStrings.noSecret, style: textTheme.bodyLarge),
        data: (secret) => secret == null
            ? Text(SpyStrings.noSecret, style: textTheme.bodyLarge)
            : _secretContent(secret, textTheme),
      );
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _setRevealed(true),
      onPointerUp: (_) => _setRevealed(false),
      onPointerCancel: (_) => _setRevealed(false),
      child: Card(
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
