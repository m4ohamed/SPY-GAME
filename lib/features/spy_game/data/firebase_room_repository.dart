import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spy_game_domain/spy_game_domain.dart';

import '../domain/phase_token.dart';
import '../domain/room_failure.dart';
import '../domain/room_repository.dart';
import 'room_mappers.dart';

/// Must match `REGION` in `spy_game_functions/src/config.ts`.
const String spyFunctionsRegion = 'europe-west1';

/// Talks to the `spygame` Cloud Functions for every write and listens to
/// Firestore for reads. Clients never write room data directly.
class FirebaseRoomRepository implements RoomRepository {
  FirebaseRoomRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: spyFunctionsRegion),
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Duration _serverOffset = Duration.zero;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<RoomJoinResult> createRoom({
    required GameModeType mode,
    required String displayName,
    RoomSettings? settings,
  }) async {
    final data = await _call('createRoom', <String, Object?>{
      'mode': mode.name,
      'displayName': displayName,
      if (settings != null) 'settings': settingsToMap(settings),
    });
    return _joinResult(data);
  }

  @override
  Future<RoomJoinResult> joinRoom({
    required String code,
    required String displayName,
  }) async {
    final data = await _call('joinRoom', <String, Object?>{
      'code': code,
      'displayName': displayName,
    });
    return _joinResult(data);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    await _call('leaveRoom', <String, Object?>{'roomId': roomId});
  }

  @override
  Future<void> kickPlayer({
    required String roomId,
    required String targetUid,
  }) async {
    await _call('kickPlayer', <String, Object?>{
      'roomId': roomId,
      'targetUid': targetUid,
    });
  }

  @override
  Future<void> startGame(String roomId) async {
    await _call('startGame', <String, Object?>{'roomId': roomId});
  }

  @override
  Future<void> cancelGame(String roomId) async {
    await _call('cancelGame', <String, Object?>{'roomId': roomId});
  }

  @override
  Future<TickResult> tick(Room room) async {
    final data = await _call('tick', <String, Object?>{
      'roomId': room.id,
      'token': phaseToken(room),
    });
    final retry = data['retryAfterMs'];
    return TickResult(
      advanced: data['advanced'] == true,
      retryAfter: retry is num ? Duration(milliseconds: retry.toInt()) : null,
    );
  }

  @override
  Future<void> submitClue({
    required String roomId,
    required String text,
  }) async {
    await _call('submitClue', <String, Object?>{
      'roomId': roomId,
      'text': text,
    });
  }

  @override
  Future<void> castVote({
    required String roomId,
    required String targetUid,
  }) async {
    await _call('castVote', <String, Object?>{
      'roomId': roomId,
      'targetUid': targetUid,
    });
  }

  @override
  Future<void> submitSpyGuess({
    required String roomId,
    required String text,
  }) async {
    await _call('submitSpyGuess', <String, Object?>{
      'roomId': roomId,
      'text': text,
    });
  }

  @override
  Future<void> heartbeat(String roomId) async {
    await _call('heartbeat', <String, Object?>{'roomId': roomId});
  }

  @override
  Future<void> registerPush({
    required String roomId,
    required String subscriptionId,
  }) async {
    await _call('registerPush', <String, Object?>{
      'roomId': roomId,
      'subscriptionId': subscriptionId,
    });
  }

  @override
  DateTime serverNow() => DateTime.now().add(_serverOffset);

  @override
  Future<void> updateSettings({
    required String roomId,
    required RoomSettings settings,
  }) async {
    await _call('updateRoomSettings', <String, Object?>{
      'roomId': roomId,
      'settings': settingsToMap(settings),
    });
  }

  @override
  Stream<Room?> watchRoom(String roomId) {
    return _rooms
        .doc(roomId)
        .snapshots()
        .map<Room?>((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return null;
          return roomFromMap(snapshot.id, data);
        })
        .transform(_mapStreamErrors<Room?>());
  }

  @override
  Stream<List<Player>> watchPlayers(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('players')
        .orderBy('joinedAt')
        .snapshots()
        .map<List<Player>>(
          (snapshot) => snapshot.docs
              .map((doc) => playerFromMap(doc.id, doc.data()))
              .toList(growable: false),
        )
        .transform(_mapStreamErrors<List<Player>>());
  }

  @override
  Stream<List<Clue>> watchClues(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('clues')
        .orderBy('createdAt')
        .snapshots()
        .map<List<Clue>>(
          (snapshot) => snapshot.docs
              .map((doc) => clueFromMap(doc.id, doc.data()))
              .toList(growable: false),
        )
        .transform(_mapStreamErrors<List<Clue>>());
  }

  @override
  Stream<PlayerSecret?> watchMySecret(String roomId) {
    final uid = currentUid;
    if (uid == null) {
      return Stream<PlayerSecret?>.error(
        const RoomException(RoomFailure.unauthenticated),
      );
    }
    return _rooms
        .doc(roomId)
        .collection('secrets')
        .doc(uid)
        .snapshots()
        .map<PlayerSecret?>((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return null;
          return secretFromMap(data);
        })
        .transform(_mapStreamErrors<PlayerSecret?>());
  }

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      throw RoomException(
        error.code == 'network-request-failed'
            ? RoomFailure.network
            : RoomFailure.unauthenticated,
        error.message,
      );
    }
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> payload,
  ) async {
    await _ensureSignedIn();
    try {
      final result = await _functions.httpsCallable(name).call<dynamic>(payload);
      final data = result.data;
      if (data is! Map) return const <String, dynamic>{};
      final map = Map<String, dynamic>.from(data);
      final serverMillis = map['serverTimeMillis'];
      if (serverMillis is num) {
        _serverOffset = Duration(
          milliseconds:
              serverMillis.toInt() - DateTime.now().millisecondsSinceEpoch,
        );
      }
      return map;
    } on FirebaseFunctionsException catch (error) {
      throw _fromFunctionsException(error);
    }
  }

  RoomJoinResult _joinResult(Map<String, dynamic> data) {
    final roomId = data['roomId'];
    final code = data['code'];
    if (roomId is! String || code is! String) {
      throw const RoomException(
        RoomFailure.unknown,
        'The server returned an unexpected response.',
      );
    }
    return RoomJoinResult(roomId: roomId, code: code);
  }
}

RoomException _fromFunctionsException(FirebaseFunctionsException error) {
  switch (error.code) {
    case 'unauthenticated':
      return RoomException(RoomFailure.unauthenticated, error.message);
    case 'unavailable':
    case 'deadline-exceeded':
      return RoomException(RoomFailure.network, error.message);
  }
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  return RoomException(
    RoomFailure.fromReason(reason is String ? reason : null),
    error.message,
  );
}

RoomException _toRoomException(Object error) {
  if (error is RoomException) return error;
  if (error is FirebaseFunctionsException) {
    return _fromFunctionsException(error);
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return RoomException(RoomFailure.notInRoom, error.message);
      case 'unavailable':
      case 'deadline-exceeded':
        return RoomException(RoomFailure.network, error.message);
    }
  }
  return RoomException(RoomFailure.unknown, error.toString());
}

StreamTransformer<T, T> _mapStreamErrors<T>() {
  return StreamTransformer<T, T>.fromHandlers(
    handleError: (Object error, StackTrace stackTrace, EventSink<T> sink) {
      sink.addError(_toRoomException(error), stackTrace);
    },
  );
}
