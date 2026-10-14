import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../domain/room_failure.dart';
import '../domain/room_repository.dart';
import 'lobby_screen.dart';
import 'providers.dart';
import 'spy_strings.dart';

/// Entry screen of the spy game: pick a name, then create or join a room.
class SpyHomeScreen extends ConsumerStatefulWidget {
  const SpyHomeScreen({super.key});

  @override
  ConsumerState<SpyHomeScreen> createState() => _SpyHomeScreenState();
}

class _SpyHomeScreenState extends ConsumerState<SpyHomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  GameModeType _mode = GameModeType.undercover;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _enterRoom(
    Future<RoomJoinResult> Function(RoomRepository repository, String name)
        action,
  ) async {
    if (_busy) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage(SpyStrings.failureMessage(RoomFailure.invalidName));
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await action(ref.read(roomRepositoryProvider), name);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LobbyScreen(roomId: result.roomId),
        ),
      );
    } on RoomException catch (error) {
      if (mounted) _showMessage(SpyStrings.failureMessage(error.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() {
    return _enterRoom(
      (repository, name) =>
          repository.createRoom(mode: _mode, displayName: name),
    );
  }

  Future<void> _join() {
    return _enterRoom(
      (repository, name) => repository.joinRoom(
        code: _codeController.text,
        displayName: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text(SpyStrings.homeTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              enabled: !_busy,
              maxLength: 20,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: SpyStrings.nameLabel,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(SpyStrings.modeTitle, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<GameModeType>(
              segments: [
                for (final mode in GameModeType.values)
                  ButtonSegment<GameModeType>(
                    value: mode,
                    label: Text(SpyStrings.modeLabel(mode)),
                  ),
              ],
              selected: {_mode},
              onSelectionChanged: _busy
                  ? null
                  : (selection) => setState(() => _mode = selection.first),
            ),
            const SizedBox(height: 8),
            Text(SpyStrings.modeDescription(_mode)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: const Text(SpyStrings.createRoom),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(SpyStrings.joinTitle, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              enabled: !_busy,
              maxLength: 6,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: textTheme.headlineSmall?.copyWith(letterSpacing: 4),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                TextInputFormatter.withFunction(
                  (oldValue, newValue) =>
                      newValue.copyWith(text: newValue.text.toUpperCase()),
                ),
              ],
              decoration: const InputDecoration(
                labelText: SpyStrings.codeLabel,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy ? null : _join,
              child: const Text(SpyStrings.joinRoom),
            ),
          ],
        ),
      ),
    );
  }
}
