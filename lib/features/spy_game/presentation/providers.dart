import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../data/firebase_room_repository.dart';
import '../data/onesignal_push_registrar.dart';
import '../domain/push_registrar.dart';
import '../domain/room_repository.dart';

/// Override this in tests with a fake [RoomRepository].
final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => FirebaseRoomRepository(),
);

/// Override this in tests, or in an app that does not use OneSignal.
final pushRegistrarProvider = Provider<PushRegistrar>(
  (ref) => OneSignalPushRegistrar(),
);

final roomProvider = StreamProvider.autoDispose.family<Room?, String>(
  (ref, roomId) => ref.watch(roomRepositoryProvider).watchRoom(roomId),
);

/// Every clue given so far in the room.
final cluesProvider = StreamProvider.autoDispose.family<List<Clue>, String>(
  (ref, roomId) => ref.watch(roomRepositoryProvider).watchClues(roomId),
);

/// The current player's own secret. Only this player can read it.
final mySecretProvider =
    StreamProvider.autoDispose.family<PlayerSecret?, String>(
  (ref, roomId) => ref.watch(roomRepositoryProvider).watchMySecret(roomId),
);

final playersProvider =
    StreamProvider.autoDispose.family<List<Player>, String>(
  (ref, roomId) => ref.watch(roomRepositoryProvider).watchPlayers(roomId),
);
