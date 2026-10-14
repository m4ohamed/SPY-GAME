import 'dart:math';

import 'package:spy_game_domain/spy_game_domain.dart';
import 'package:test/test.dart';

List<String> uids(int count) =>
    List<String>.generate(count, (index) => 'p$index');

const coffeeTea = WordEntry(
  id: 'w1',
  categoryId: 'drinks',
  language: WordLanguage.ar,
  word: 'قهوة',
  similarWord: 'شاي',
);

const airport = WordEntry(
  id: 'w2',
  categoryId: 'places',
  language: WordLanguage.ar,
  word: 'مطار',
);

RoundSnapshot snapshot({
  required int round,
  required Set<String> spies,
  required Set<String> alive,
  String? eliminated,
}) {
  return RoundSnapshot(
    round: round,
    spyUids: spies,
    aliveUids: alive,
    eliminatedUid: eliminated,
  );
}

Matcher gameOver(GameWinner winner, GameEndReason reason) {
  return isA<GameOver>().having(
    (result) => result.outcome,
    'outcome',
    equals(GameOutcome(winner: winner, reason: reason)),
  );
}

void main() {
  group('spy counts', () {
    test('undercover scales with players and stays below half', () {
      const mode = GameModes.undercover;
      expect(mode.defaultSpyCount(4), 1);
      expect(mode.defaultSpyCount(7), 1);
      expect(mode.defaultSpyCount(8), 2);
      expect(mode.defaultSpyCount(11), 2);
      expect(mode.defaultSpyCount(12), 3);
      expect(mode.maxSpyCount(4), 1);
      expect(mode.maxSpyCount(12), 5);
    });

    test('imposter always has exactly one spy', () {
      const mode = GameModes.imposter;
      expect(mode.defaultSpyCount(3), 1);
      expect(mode.defaultSpyCount(12), 1);
      expect(mode.maxSpyCount(12), 1);
    });
  });

  group('word eligibility', () {
    test('undercover needs a different similar word', () {
      expect(GameModes.undercover.isEligible(coffeeTea), isTrue);
      expect(GameModes.undercover.isEligible(airport), isFalse);
      const sameWord = WordEntry(
        id: 'w3',
        categoryId: 'drinks',
        language: WordLanguage.ar,
        word: 'قهوة',
        similarWord: 'القهوه',
      );
      expect(GameModes.undercover.isEligible(sameWord), isFalse);
    });

    test('imposter accepts any non-empty word', () {
      expect(GameModes.imposter.isEligible(airport), isTrue);
      expect(GameModes.imposter.isEligible(coffeeTea), isTrue);
    });
  });

  group('assignSecrets', () {
    test('undercover hides roles and deals two different words', () {
      final assignment = GameModes.undercover.assignSecrets(
        playerUids: uids(8),
        word: coffeeTea,
        spyCount: 2,
        random: Random(7),
      );

      expect(assignment.secrets.length, 8);
      expect(assignment.spyUids.length, 2);
      expect(assignment.secrets.values.every((s) => s.role == null), isTrue);
      expect(
        {assignment.civilianWord, assignment.spyWord},
        {'قهوة', 'شاي'},
      );
      for (final entry in assignment.secrets.entries) {
        final expected = assignment.spyUids.contains(entry.key)
            ? assignment.spyWord
            : assignment.civilianWord;
        expect(entry.value.word, expected);
      }
    });

    test('imposter gives the spy a role and no word', () {
      final assignment = GameModes.imposter.assignSecrets(
        playerUids: uids(6),
        word: airport,
        spyCount: 1,
        random: Random(3),
      );

      expect(assignment.spyUids.length, 1);
      expect(assignment.spyWord, isNull);
      final spyUid = assignment.spyUids.single;
      expect(
        assignment.secrets[spyUid],
        const PlayerSecret(role: PlayerRole.spy),
      );
      for (final entry in assignment.secrets.entries) {
        if (entry.key == spyUid) continue;
        expect(
          entry.value,
          const PlayerSecret(role: PlayerRole.civilian, word: 'مطار'),
        );
      }
    });

    test('every player can end up as the spy', () {
      final players = uids(4);
      final seen = <String>{};
      for (var seed = 0; seed < 200; seed++) {
        final assignment = GameModes.imposter.assignSecrets(
          playerUids: players,
          word: airport,
          spyCount: 1,
          random: Random(seed),
        );
        seen.addAll(assignment.spyUids);
      }
      expect(seen, players.toSet());
    });

    test('rejects invalid input', () {
      expect(
        () => GameModes.undercover.assignSecrets(
          playerUids: uids(6),
          word: airport,
          spyCount: 1,
          random: Random(1),
        ),
        throwsArgumentError,
      );
      expect(
        () => GameModes.undercover.assignSecrets(
          playerUids: uids(6),
          word: coffeeTea,
          spyCount: 3,
          random: Random(1),
        ),
        throwsArgumentError,
      );
      expect(
        () => GameModes.undercover.assignSecrets(
          playerUids: ['a', 'a', 'b', 'c'],
          word: coffeeTea,
          spyCount: 1,
          random: Random(1),
        ),
        throwsArgumentError,
      );
      expect(
        () => GameModes.undercover.assignSecrets(
          playerUids: uids(3),
          word: coffeeTea,
          spyCount: 1,
          random: Random(1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('validateSettings', () {
    test('accepts default settings with enough players', () {
      final settings = RoomSettings(mode: GameModeType.undercover);
      expect(GameModes.undercover.validateSettings(settings, 6), isEmpty);
    });

    test('reports player count, mode, spy count, and duration problems', () {
      final undercover = RoomSettings(mode: GameModeType.undercover);
      expect(
        GameModes.undercover.validateSettings(undercover, 3),
        contains(SettingsIssue.tooFewPlayers),
      );
      expect(
        GameModes.undercover.validateSettings(undercover, 13),
        contains(SettingsIssue.tooManyPlayers),
      );
      expect(
        GameModes.imposter.validateSettings(undercover, 5),
        contains(SettingsIssue.wrongMode),
      );
      expect(
        GameModes.undercover.validateSettings(
          undercover.copyWith(spyCountOverride: 3),
          6,
        ),
        contains(SettingsIssue.invalidSpyCount),
      );
      expect(
        GameModes.imposter.validateSettings(
          RoomSettings(mode: GameModeType.imposter, spyCountOverride: 2),
          8,
        ),
        contains(SettingsIssue.invalidSpyCount),
      );
      expect(
        GameModes.undercover.validateSettings(
          undercover.copyWith(clueSeconds: 2),
          6,
        ),
        contains(SettingsIssue.invalidDuration),
      );
    });
  });

  group('undercover elimination', () {
    const mode = GameModes.undercover;

    test('civilians win when the last spy is voted out', () {
      final result = mode.onElimination(
        snapshot(
          round: 1,
          spies: {'p0'},
          alive: {'p1', 'p2', 'p3', 'p4', 'p5'},
          eliminated: 'p0',
        ),
      );
      expect(result, gameOver(GameWinner.civilians, GameEndReason.allSpiesCaught));
    });

    test('game continues, then spies win at parity', () {
      final first = mode.onElimination(
        snapshot(
          round: 1,
          spies: {'p0'},
          alive: {'p0', 'p2', 'p3'},
          eliminated: 'p1',
        ),
      );
      expect(first, isA<NextRound>());

      final second = mode.onElimination(
        snapshot(
          round: 2,
          spies: {'p0'},
          alive: {'p0', 'p3'},
          eliminated: 'p2',
        ),
      );
      expect(
        second,
        gameOver(GameWinner.spies, GameEndReason.spiesReachedParity),
      );
    });

    test('no elimination continues until the round cap', () {
      final everyone = uids(8).toSet();
      expect(
        mode.onElimination(snapshot(round: 3, spies: {'p0'}, alive: everyone)),
        isA<NextRound>(),
      );
      expect(
        mode.onElimination(
          snapshot(round: mode.maxRounds, spies: {'p0'}, alive: everyone),
        ),
        gameOver(GameWinner.spies, GameEndReason.roundLimitReached),
      );
    });
  });

  group('imposter elimination', () {
    const mode = GameModes.imposter;
    final everyoneButSpy = {'p0', 'p1', 'p3'};

    test('a caught spy gets a guess', () {
      final result = mode.onElimination(
        snapshot(
          round: 1,
          spies: {'p2'},
          alive: everyoneButSpy,
          eliminated: 'p2',
        ),
      );
      expect(
        result,
        isA<AwaitSpyGuess>().having((r) => r.spyUid, 'spyUid', 'p2'),
      );
    });

    test('the spy wins when a civilian or nobody is eliminated', () {
      final civilianOut = mode.onElimination(
        snapshot(
          round: 1,
          spies: {'p2'},
          alive: {'p0', 'p2', 'p3'},
          eliminated: 'p1',
        ),
      );
      expect(civilianOut, gameOver(GameWinner.spies, GameEndReason.spyNotCaught));

      final nobodyOut = mode.onElimination(
        snapshot(round: 1, spies: {'p2'}, alive: {'p0', 'p1', 'p2', 'p3'}),
      );
      expect(nobodyOut, gameOver(GameWinner.spies, GameEndReason.spyNotCaught));
    });

    test('the guess decides the winner', () {
      expect(
        mode.resolveSpyGuess(correct: true),
        const GameOutcome(
          winner: GameWinner.spies,
          reason: GameEndReason.spyGuessedWord,
        ),
      );
      expect(
        mode.resolveSpyGuess(correct: false),
        const GameOutcome(
          winner: GameWinner.civilians,
          reason: GameEndReason.spyGuessFailed,
        ),
      );
      expect(mode.isSpyGuessCorrect('المطار', 'مطار'), isTrue);
      expect(mode.isSpyGuessCorrect('ملعب', 'مطار'), isFalse);
    });

    test('undercover does not grant a guess', () {
      expect(
        () => GameModes.undercover.resolveSpyGuess(correct: true),
        throwsStateError,
      );
    });
  });

  group('VoteCounter', () {
    final alive = {'p0', 'p1', 'p2', 'p3'};

    test('a unique leader is eliminated', () {
      final result = VoteCounter.count(
        votes: {'p0': 'p3', 'p1': 'p3', 'p2': 'p3', 'p3': 'p0'},
        aliveUids: alive,
      );
      expect(result.eliminatedUid, 'p3');
      expect(result.tally, {'p3': 3, 'p0': 1});
      expect(result.isTie, isFalse);
    });

    test('a tie lists the leaders sorted and eliminates nobody', () {
      final result = VoteCounter.count(
        votes: {'p0': 'p1', 'p1': 'p0'},
        aliveUids: {'p0', 'p1', 'p2'},
      );
      expect(result.isTie, isTrue);
      expect(result.tiedUids, ['p0', 'p1']);
      expect(result.eliminatedUid, isNull);
    });

    test('self votes and dead voters are ignored', () {
      final selfVote = VoteCounter.count(
        votes: {'p0': 'p0'},
        aliveUids: alive,
      );
      expect(selfVote.hasVotes, isFalse);
      expect(selfVote.eliminatedUid, isNull);
      expect(selfVote.isTie, isFalse);

      final deadVoter = VoteCounter.count(
        votes: {'p9': 'p0'},
        aliveUids: alive,
      );
      expect(deadVoter.hasVotes, isFalse);
    });

    test('a revote only counts votes for the candidates', () {
      final result = VoteCounter.count(
        votes: {'p2': 'p0', 'p3': 'p2'},
        aliveUids: alive,
        candidateUids: {'p0', 'p1'},
      );
      expect(result.eliminatedUid, 'p0');
      expect(result.tally, {'p0': 1});
    });

    test('validateVote explains rejections', () {
      expect(
        VoteCounter.validateVote(
          voterUid: 'x',
          targetUid: 'p0',
          aliveUids: alive,
        ),
        VoteRejection.voterNotAlive,
      );
      expect(
        VoteCounter.validateVote(
          voterUid: 'p0',
          targetUid: 'p0',
          aliveUids: alive,
        ),
        VoteRejection.selfVote,
      );
      expect(
        VoteCounter.validateVote(
          voterUid: 'p0',
          targetUid: 'x',
          aliveUids: alive,
        ),
        VoteRejection.targetNotAlive,
      );
      expect(
        VoteCounter.validateVote(
          voterUid: 'p0',
          targetUid: 'p2',
          aliveUids: alive,
          candidateUids: {'p1'},
        ),
        VoteRejection.targetNotCandidate,
      );
      expect(
        VoteCounter.validateVote(
          voterUid: 'p0',
          targetUid: 'p1',
          aliveUids: alive,
        ),
        isNull,
      );
    });
  });

  group('AnswerMatcher', () {
    test('forgives common Arabic spelling variations', () {
      expect(AnswerMatcher.matches('القهوة', 'قهوه'), isTrue);
      expect(AnswerMatcher.matches('أَحْمَد', 'احمد'), isTrue);
      expect(AnswerMatcher.matches('مستشفى', 'مستشفي'), isTrue);
      expect(AnswerMatcher.matches('٣ ورود', '3 ورود'), isTrue);
    });

    test('ignores case, punctuation, and spacing', () {
      expect(AnswerMatcher.matches('Coca-Cola', 'coca cola'), isTrue);
      expect(AnswerMatcher.matches(' Ice  Cream ', 'icecream'), isTrue);
    });

    test('does not match different or empty answers', () {
      expect(AnswerMatcher.matches('قهوة', 'شاي'), isFalse);
      expect(AnswerMatcher.matches('', ''), isFalse);
      expect(AnswerMatcher.matches('   ', 'مطار'), isFalse);
    });
  });

  group('PhaseMachine', () {
    test('allows the normal flow and the next-round and revote loops', () {
      expect(PhaseMachine.canTransition(GamePhase.lobby, GamePhase.reveal), isTrue);
      expect(PhaseMachine.canTransition(GamePhase.reveal, GamePhase.clues), isTrue);
      expect(PhaseMachine.canTransition(GamePhase.clues, GamePhase.discussion), isTrue);
      expect(PhaseMachine.canTransition(GamePhase.discussion, GamePhase.vote), isTrue);
      expect(PhaseMachine.canTransition(GamePhase.vote, GamePhase.vote), isTrue);
      expect(PhaseMachine.canTransition(GamePhase.vote, GamePhase.clues), isTrue);
      expect(PhaseMachine.canTransition(GamePhase.vote, GamePhase.spyGuess), isTrue);
      expect(PhaseMachine.canTransition(GamePhase.spyGuess, GamePhase.result), isTrue);
      expect(PhaseMachine.canTransition(GamePhase.result, GamePhase.lobby), isTrue);
    });

    test('allows the host to cancel an active game', () {
      expect(PhaseMachine.canTransition(GamePhase.clues, GamePhase.lobby), isTrue);
    });

    test('rejects skipping phases', () {
      expect(PhaseMachine.canTransition(GamePhase.lobby, GamePhase.vote), isFalse);
      expect(PhaseMachine.canTransition(GamePhase.result, GamePhase.clues), isFalse);
      expect(PhaseMachine.canTransition(GamePhase.clues, GamePhase.vote), isFalse);
    });
  });

  group('entities', () {
    Room room({List<String> turnOrder = const ['p0', 'p1']}) {
      return Room(
        id: 'r1',
        code: 'ABC234',
        hostUid: 'p0',
        settings: RoomSettings(mode: GameModeType.undercover),
        createdAt: DateTime.utc(2026, 10, 11),
        turnOrder: turnOrder,
      );
    }

    test('rooms compare by value and expose unmodifiable lists', () {
      expect(room(), room());
      expect(room().hashCode, room().hashCode);
      expect(room(), isNot(room(turnOrder: const ['p1', 'p0'])));
      expect(() => room().turnOrder.add('p2'), throwsUnsupportedError);
    });

    test('copyWith can set and clear nullable fields', () {
      final started = room().copyWith(
        phase: GamePhase.clues,
        round: 1,
        turnUid: 'p0',
        phaseEndsAt: DateTime.utc(2026, 10, 11, 12),
      );
      expect(started.isTurnOf('p0'), isTrue);
      expect(started.isTurnOf('p1'), isFalse);
      expect(started.hasActiveGame, isTrue);

      final cleared = started.copyWith(
        clearTurnUid: true,
        clearPhaseEndsAt: true,
      );
      expect(cleared.turnUid, isNull);
      expect(cleared.phaseEndsAt, isNull);
    });

    test('settings expose the duration of each timed phase', () {
      final settings = RoomSettings(mode: GameModeType.imposter);
      expect(settings.durationFor(GamePhase.lobby), isNull);
      expect(settings.durationFor(GamePhase.result), isNull);
      expect(settings.durationFor(GamePhase.clues), const Duration(seconds: 30));
      expect(settings.durationFor(GamePhase.discussion), const Duration(seconds: 150));
      expect(settings.durationFor(GamePhase.vote), const Duration(seconds: 45));
    });
  });
}
