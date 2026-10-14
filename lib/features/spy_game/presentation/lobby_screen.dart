import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../domain/room_failure.dart';
import '../domain/room_repository.dart';
import 'providers.dart';
import 'spy_strings.dart';
import 'widgets/clues_panel.dart';
import 'widgets/phase_ticker.dart';
import 'widgets/players_card.dart';
import 'widgets/presence_keeper.dart';
import 'widgets/result_panel.dart';
import 'widgets/role_card.dart';
import 'widgets/spy_guess_panel.dart';
import 'widgets/vote_panel.dart';

const List<int> _clueOptions = [15, 20, 30, 45, 60];
const List<int> _discussionOptions = [60, 90, 120, 150, 180, 240, 300];
const List<int> _voteOptions = [20, 30, 45, 60, 90];

/// The screen of a room. It shows the lobby while the room waits for players
/// and the game view (phase, the player's own secret, and everyone's status)
/// once the host has started the game.
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _busy = false;
  bool _leaving = false;
  void Function()? _stopPushListener;

  RoomRepository get _repository => ref.read(roomRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _setUpPush();
  }

  @override
  void dispose() {
    _stopPushListener?.call();
    super.dispose();
  }

  /// Notifications are a convenience: if anything fails here the game still
  /// works, so errors are only logged.
  Future<void> _setUpPush() async {
    final registrar = ref.read(pushRegistrarProvider);
    final repository = ref.read(roomRepositoryProvider);

    Future<void> register(String id) async {
      try {
        await repository.registerPush(
          roomId: widget.roomId,
          subscriptionId: id,
        );
      } on RoomException catch (error) {
        debugPrint('Could not register for notifications: $error');
      }
    }

    try {
      final id = await registrar.prepare();
      if (!mounted) return;
      if (id != null) await register(id);
      if (!mounted) return;
      _stopPushListener = registrar.listen(register);
    } catch (error) {
      debugPrint('Notifications are not available: $error');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _guarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on RoomException catch (error) {
      if (mounted) _showMessage(SpyStrings.failureMessage(error.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(SpyStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _leave() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _leaving = true;
    });
    try {
      await _repository.leaveRoom(widget.roomId);
      if (mounted) Navigator.of(context).pop();
    } on RoomException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _leaving = false;
        });
        _showMessage(SpyStrings.failureMessage(error.failure));
      }
    }
  }

  /// Leaving mid-game asks for confirmation because the seat cannot be
  /// reclaimed.
  Future<void> _requestLeave(Room room) async {
    if (_busy) return;
    final needsConfirmation =
        room.phase != GamePhase.lobby && room.phase != GamePhase.result;
    if (needsConfirmation) {
      final confirmed = await _confirm(
        title: SpyStrings.leaveGameTitle,
        message: SpyStrings.leaveGameMessage,
        confirmLabel: SpyStrings.leaveRoom,
      );
      if (!confirmed || !mounted) return;
    }
    await _leave();
  }

  Future<void> _cancelGame() async {
    final confirmed = await _confirm(
      title: SpyStrings.cancelGameTitle,
      message: SpyStrings.cancelGameMessage,
      confirmLabel: SpyStrings.confirm,
    );
    if (!confirmed || !mounted) return;
    await _guarded(() => _repository.cancelGame(widget.roomId));
  }

  Future<void> _startGame() {
    return _guarded(() => _repository.startGame(widget.roomId));
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) _showMessage(SpyStrings.codeCopied);
  }

  Future<void> _updateSettings(RoomSettings settings) {
    return _guarded(
      () => _repository.updateSettings(
        roomId: widget.roomId,
        settings: settings,
      ),
    );
  }

  Future<void> _kick(Player player) {
    return _guarded(
      () => _repository.kickPlayer(
        roomId: widget.roomId,
        targetUid: player.uid,
      ),
    );
  }

  String _errorText(Object error) {
    final failure =
        error is RoomException ? error.failure : RoomFailure.unknown;
    return SpyStrings.failureMessage(failure);
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final playersAsync = ref.watch(playersProvider(widget.roomId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: _leaving
          ? const _LoadingScaffold()
          : roomAsync.when(
              loading: () => const _LoadingScaffold(),
              error: (error, _) => _EndedScaffold(message: _errorText(error)),
              data: (room) {
                if (room == null) {
                  return const _EndedScaffold(message: SpyStrings.roomGone);
                }
                return playersAsync.when(
                  loading: () => const _LoadingScaffold(),
                  error: (error, _) =>
                      _EndedScaffold(message: _errorText(error)),
                  data: (players) => _buildRoom(context, room, players),
                );
              },
            ),
    );
  }

  Widget _buildRoom(BuildContext context, Room room, List<Player> players) {
    final uid = _repository.currentUid;
    final isHost = uid != null && room.isHost(uid);
    final inLobby = room.phase == GamePhase.lobby;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestLeave(room);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(inLobby ? SpyStrings.lobbyTitle : SpyStrings.gameTitle),
          actions: [
            IconButton(
              tooltip: SpyStrings.leaveRoom,
              icon: const Icon(Icons.exit_to_app),
              onPressed: _busy ? null : () => _requestLeave(room),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: inLobby
                    ? _lobbyChildren(context, room, players, uid, isHost)
                    : _gameChildren(context, room, players, uid, isHost),
              ),
            ),
            // Kept outside the list: list items are disposed when scrolled
            // away, and these must keep running while the room is open.
            PresenceKeeper(roomId: widget.roomId),
            if (!inLobby) PhaseTicker(room: room),
          ],
        ),
      ),
    );
  }

  List<Widget> _lobbyChildren(
    BuildContext context,
    Room room,
    List<Player> players,
    String? uid,
    bool isHost,
  ) {
    final mode = GameModes.of(room.settings.mode);
    final missing = mode.minPlayers - players.length;
    final issues = mode.validateSettings(room.settings, players.length);
    final textTheme = Theme.of(context).textTheme;

    return [
      _CodeCard(code: room.code, onCopy: () => _copyCode(room.code)),
      const SizedBox(height: 16),
      PlayersCard(
        players: players,
        hostUid: room.hostUid,
        currentUid: uid,
        onKick: isHost && !_busy ? _kick : null,
      ),
      const SizedBox(height: 16),
      _SettingsCard(
        settings: room.settings,
        playerCount: players.length,
        isHost: isHost,
        busy: _busy,
        onChanged: _updateSettings,
      ),
      const SizedBox(height: 16),
      Text(
        missing > 0
            ? SpyStrings.missingPlayers(missing)
            : SpyStrings.readyToStart,
        textAlign: TextAlign.center,
        style: textTheme.titleMedium,
      ),
      if (issues.contains(SettingsIssue.invalidSpyCount)) ...[
        const SizedBox(height: 8),
        Text(
          SpyStrings.spyCountTooHigh,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
      const SizedBox(height: 16),
      if (isHost)
        FilledButton.icon(
          onPressed: _busy || issues.isNotEmpty ? null : _startGame,
          icon: const Icon(Icons.play_arrow),
          label: const Text(SpyStrings.startGame),
        )
      else
        Text(
          SpyStrings.waitingForHost,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
    ];
  }

  List<Widget> _gameChildren(
    BuildContext context,
    Room room,
    List<Player> players,
    String? uid,
    bool isHost,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final endsAt = room.phaseEndsAt;
    final reveal = room.reveal;

    final Widget? phasePanel;
    switch (room.phase) {
      case GamePhase.clues:
        phasePanel = CluesPanel(
          roomId: widget.roomId,
          room: room,
          players: players,
          uid: uid,
        );
      case GamePhase.vote:
        phasePanel = VotePanel(
          roomId: widget.roomId,
          room: room,
          players: players,
          uid: uid,
        );
      case GamePhase.spyGuess:
        phasePanel = SpyGuessPanel(
          roomId: widget.roomId,
          room: room,
          players: players,
          uid: uid,
        );
      case GamePhase.result:
        phasePanel =
            reveal == null ? null : ResultPanel(reveal: reveal, players: players);
      case GamePhase.lobby:
      case GamePhase.reveal:
      case GamePhase.discussion:
        phasePanel = null;
    }

    final hint = switch (room.phase) {
      GamePhase.reveal => SpyStrings.revealHint,
      GamePhase.discussion => SpyStrings.discussionHint,
      _ => null,
    };

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                SpyStrings.phaseLabel(room.phase),
                style: textTheme.headlineSmall,
              ),
              if (room.round > 0) ...[
                const SizedBox(height: 4),
                Text(SpyStrings.roundNumber(room.round)),
              ],
              if (endsAt != null) ...[
                const SizedBox(height: 8),
                PhaseCountdown(endsAt: endsAt),
              ],
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(hint, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
      if (phasePanel != null) ...[
        const SizedBox(height: 16),
        phasePanel,
      ],
      const SizedBox(height: 16),
      RoleCard(roomId: widget.roomId),
      const SizedBox(height: 16),
      PlayersCard(players: players, hostUid: room.hostUid, currentUid: uid),
      const SizedBox(height: 16),
      ..._endControls(room, isHost, textTheme),
    ];
  }

  /// At the end of a game the host brings everyone back to the lobby. During
  /// a game the host can abandon it.
  List<Widget> _endControls(Room room, bool isHost, TextTheme textTheme) {
    if (room.phase == GamePhase.result) {
      if (isHost) {
        return [
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _guarded(() => _repository.cancelGame(widget.roomId)),
            icon: const Icon(Icons.replay),
            label: const Text(SpyStrings.backToLobby),
          ),
        ];
      }
      return [
        Text(
          SpyStrings.waitingForHostReturn,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
      ];
    }
    if (isHost) {
      return [
        OutlinedButton.icon(
          onPressed: _busy ? null : _cancelGame,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text(SpyStrings.cancelGame),
        ),
      ];
    }
    return const [];
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _EndedScaffold extends StatelessWidget {
  const _EndedScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(SpyStrings.lobbyTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(SpyStrings.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(SpyStrings.roomCode, style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  code,
                  textDirection: TextDirection.ltr,
                  style: textTheme.displaySmall?.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: SpyStrings.copyCode,
                  icon: const Icon(Icons.copy),
                  onPressed: onCopy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.settings,
    required this.playerCount,
    required this.isHost,
    required this.busy,
    required this.onChanged,
  });

  final RoomSettings settings;
  final int playerCount;
  final bool isHost;
  final bool busy;
  final ValueChanged<RoomSettings> onChanged;

  static List<DropdownMenuItem<int>> _secondsItems(
    List<int> base,
    int current,
  ) {
    final values = <int>{...base, current}.toList()..sort();
    return [
      for (final value in values)
        DropdownMenuItem<int>(
          value: value,
          child: Text(SpyStrings.seconds(value)),
        ),
    ];
  }

  List<Widget> _editableRows() {
    final mode = GameModes.of(settings.mode);
    final maxSpies = mode.maxSpyCount(playerCount);
    final override = settings.spyCountOverride;
    final spyOptions = <int>{
      for (var count = 1; count <= maxSpies; count++) count,
      if (override != null) override,
    }.toList()
      ..sort();

    return [
      SegmentedButton<GameModeType>(
        segments: [
          for (final type in GameModeType.values)
            ButtonSegment<GameModeType>(
              value: type,
              label: Text(SpyStrings.modeLabel(type)),
            ),
        ],
        selected: {settings.mode},
        onSelectionChanged: busy
            ? null
            : (selection) => onChanged(
                  settings.copyWith(
                    mode: selection.first,
                    clearSpyCountOverride: true,
                  ),
                ),
      ),
      const SizedBox(height: 4),
      Text(SpyStrings.modeDescription(settings.mode)),
      const SizedBox(height: 12),
      SegmentedButton<WordLanguage>(
        segments: [
          for (final language in WordLanguage.values)
            ButtonSegment<WordLanguage>(
              value: language,
              label: Text(SpyStrings.languageName(language)),
            ),
        ],
        selected: {settings.language},
        onSelectionChanged: busy
            ? null
            : (selection) =>
                onChanged(settings.copyWith(language: selection.first)),
      ),
      _DropdownRow<int?>(
        label: SpyStrings.spyCountLabel,
        value: override,
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text(SpyStrings.spyCountAuto),
          ),
          for (final count in spyOptions)
            DropdownMenuItem<int?>(value: count, child: Text('$count')),
        ],
        onChanged: busy
            ? null
            : (value) => onChanged(
                  value == null
                      ? settings.copyWith(clearSpyCountOverride: true)
                      : settings.copyWith(spyCountOverride: value),
                ),
      ),
      _DropdownRow<int>(
        label: SpyStrings.clueTimeLabel,
        value: settings.clueSeconds,
        items: _secondsItems(_clueOptions, settings.clueSeconds),
        onChanged: busy
            ? null
            : (value) {
                if (value != null) {
                  onChanged(settings.copyWith(clueSeconds: value));
                }
              },
      ),
      _DropdownRow<int>(
        label: SpyStrings.discussionTimeLabel,
        value: settings.discussionSeconds,
        items: _secondsItems(_discussionOptions, settings.discussionSeconds),
        onChanged: busy
            ? null
            : (value) {
                if (value != null) {
                  onChanged(settings.copyWith(discussionSeconds: value));
                }
              },
      ),
      _DropdownRow<int>(
        label: SpyStrings.voteTimeLabel,
        value: settings.voteSeconds,
        items: _secondsItems(_voteOptions, settings.voteSeconds),
        onChanged: busy
            ? null
            : (value) {
                if (value != null) {
                  onChanged(settings.copyWith(voteSeconds: value));
                }
              },
      ),
    ];
  }

  List<Widget> _readOnlyRows() {
    return [
      _InfoRow(
        label: SpyStrings.modeTitle,
        value: SpyStrings.modeLabel(settings.mode),
      ),
      _InfoRow(
        label: SpyStrings.languageLabel,
        value: SpyStrings.languageName(settings.language),
      ),
      _InfoRow(
        label: SpyStrings.spyCountLabel,
        value: SpyStrings.spyCount(settings.spyCountOverride),
      ),
      _InfoRow(
        label: SpyStrings.clueTimeLabel,
        value: SpyStrings.seconds(settings.clueSeconds),
      ),
      _InfoRow(
        label: SpyStrings.discussionTimeLabel,
        value: SpyStrings.seconds(settings.discussionSeconds),
      ),
      _InfoRow(
        label: SpyStrings.voteTimeLabel,
        value: SpyStrings.seconds(settings.voteSeconds),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SpyStrings.settingsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...(isHost ? _editableRows() : _readOnlyRows()),
          ],
        ),
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        DropdownButton<T>(value: value, items: items, onChanged: onChanged),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
