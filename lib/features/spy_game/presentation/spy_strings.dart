import 'package:spy_game_domain/spy_game_domain.dart';

import '../domain/room_failure.dart';

/// All user-facing text of the spy game screens. Move these to ARB files if
/// the app is localized.
abstract final class SpyStrings {
  static const String homeTitle = 'مَن الجاسوس؟';
  static const String nameLabel = 'اسمك في اللعبة';
  static const String modeTitle = 'وضع اللعب';
  static const String createRoom = 'إنشاء غرفة';
  static const String joinTitle = 'الانضمام إلى غرفة';
  static const String codeLabel = 'كود الغرفة';
  static const String joinRoom = 'انضم';

  static const String lobbyTitle = 'غرفة الانتظار';
  static const String roomCode = 'كود الغرفة';
  static const String codeCopied = 'تم نسخ الكود';
  static const String copyCode = 'نسخ الكود';
  static const String playersTitle = 'اللاعبون';
  static const String host = 'المضيف';
  static const String you = 'أنت';
  static const String kick = 'طرد اللاعب';
  static const String leaveRoom = 'مغادرة الغرفة';
  static const String back = 'رجوع';

  static const String settingsTitle = 'الإعدادات';
  static const String languageLabel = 'لغة الكلمات';
  static const String spyCountLabel = 'عدد الجواسيس';
  static const String spyCountAuto = 'تلقائي';
  static const String clueTimeLabel = 'مدة التلميح';
  static const String discussionTimeLabel = 'مدة النقاش';
  static const String voteTimeLabel = 'مدة التصويت';
  static const String readyToStart = 'العدد مكتمل، الغرفة جاهزة للبدء';
  static const String spyCountTooHigh =
      'عدد الجواسيس أكبر من المسموح لهذا العدد من اللاعبين';
  static const String roomGone = 'لم تعد هذه الغرفة موجودة';

  static const String startGame = 'ابدأ اللعبة';
  static const String waitingForHost = 'بانتظار المضيف ليبدأ اللعبة';
  static const String gameTitle = 'اللعبة';
  static const String roundLabel = 'الجولة';
  static const String revealHint = 'اقرأ كلمتك ولا تُريها لأحد';
  static const String cancelGame = 'إنهاء اللعبة';
  static const String cancelGameTitle = 'إنهاء اللعبة؟';
  static const String cancelGameMessage =
      'سيعود الجميع إلى غرفة الانتظار وتُحذف الأدوار الحالية.';
  static const String leaveGameTitle = 'مغادرة اللعبة؟';
  static const String leaveGameMessage =
      'ستبقى اللعبة جارية بدونك ولن تتمكن من العودة إليها.';
  static const String confirm = 'تأكيد';
  static const String cancel = 'إلغاء';
  static const String disconnected = 'غير متصل';
  static const String eliminated = 'خرج من اللعبة';

  static const String holdToReveal = 'اضغط مع الاستمرار لإظهار كلمتك';
  static const String yourWord = 'كلمتك';
  static const String youAreSpy = 'أنت الجاسوس';
  static const String youAreCivilian = 'أنت مدني';
  static const String spyHint =
      'لا توجد كلمة لك، استمع للتلميحات وحاول أن تندمج.';
  static const String noSecret = 'لا توجد كلمة لك في هذه الجولة';

  static const String cluesTitle = 'التلميحات';
  static const String yourTurnClue = 'دورك: أعطِ تلميحًا قصيرًا';
  static const String clueHint = 'اكتب تلميحك';
  static const String send = 'إرسال';
  static const String noClues = 'لا توجد تلميحات بعد';
  static const String earlierRounds = 'الجولات السابقة';
  static const String noSpeaker = 'لا يوجد لاعب متاح للتلميح';
  static const String discussionHint =
      'ناقشوا وحاولوا معرفة الجاسوس، ثم يبدأ التصويت';
  static const String voteTitle = 'صوّت على من تظنه الجاسوس';
  static const String revoteTitle = 'تعادل! أعيدوا التصويت بين المتعادلين';
  static const String voteRecorded = 'تم تسجيل صوتك';
  static const String outOfGame = 'أنت خارج اللعبة، تابع المشاهدة';
  static const String guessTitleSelf = 'انكشفت! خمّن كلمة المدنيين لتفوز';
  static const String guessHint = 'اكتب تخمينك';
  static const String winnerCivilians = 'فاز المدنيون';
  static const String winnerSpy = 'فاز الجاسوس';
  static const String winnerSpies = 'فاز الجواسيس';
  static const String civilianWordLabel = 'كلمة المدنيين';
  static const String spyWordLabel = 'كلمة الجاسوس';
  static const String spiesLabel = 'الجواسيس';
  static const String guessLabel = 'تخمين الجاسوس';
  static const String tallyTitle = 'الأصوات في التصويت الحاسم';
  static const String backToLobby = 'العودة إلى غرفة الانتظار';
  static const String waitingForHostReturn =
      'بانتظار المضيف ليعيدكم إلى الغرفة';
  static const String unknownPlayer = 'لاعب';

  static String modeLabel(GameModeType mode) {
    switch (mode) {
      case GameModeType.undercover:
        return 'متخفٍّ';
      case GameModeType.imposter:
        return 'محتال';
    }
  }

  static String modeDescription(GameModeType mode) {
    switch (mode) {
      case GameModeType.undercover:
        return 'الجاسوس يحصل على كلمة قريبة من كلمة الجميع ولا يعرف أنه جاسوس.';
      case GameModeType.imposter:
        return 'الجاسوس بلا كلمة ويعرف دوره، ولو انكشف يحاول تخمين الكلمة.';
    }
  }

  static String phaseLabel(GamePhase phase) {
    switch (phase) {
      case GamePhase.lobby:
        return 'الانتظار';
      case GamePhase.reveal:
        return 'كشف الأدوار';
      case GamePhase.clues:
        return 'التلميحات';
      case GamePhase.discussion:
        return 'النقاش';
      case GamePhase.vote:
        return 'التصويت';
      case GamePhase.spyGuess:
        return 'تخمين الجاسوس';
      case GamePhase.result:
        return 'النتيجة';
    }
  }

  static String languageName(WordLanguage language) {
    switch (language) {
      case WordLanguage.ar:
        return 'العربية';
      case WordLanguage.en:
        return 'English';
    }
  }

  static String seconds(int value) => '$value ثانية';

  static String turnOf(String name) => 'دور $name';

  static String roundNumber(int round) => 'الجولة $round';

  static String votesProgress(int voted, int total) =>
      '$voted من $total صوّتوا';

  static String guessWaiting(String name) =>
      '$name كُشف ويحاول تخمين الكلمة';

  static String votesCount(int count) {
    switch (count) {
      case 1:
        return 'صوت واحد';
      case 2:
        return 'صوتان';
      default:
        return count <= 10 ? '$count أصوات' : '$count صوتًا';
    }
  }

  static String winnerText(GameWinner winner, int spyCount) {
    switch (winner) {
      case GameWinner.civilians:
        return winnerCivilians;
      case GameWinner.spies:
        return spyCount > 1 ? winnerSpies : winnerSpy;
    }
  }

  static String endReason(GameEndReason reason) {
    switch (reason) {
      case GameEndReason.allSpiesCaught:
        return 'تم كشف كل الجواسيس';
      case GameEndReason.spiesReachedParity:
        return 'تساوى عدد الجواسيس مع عدد المدنيين';
      case GameEndReason.spyNotCaught:
        return 'لم يُكشف الجاسوس';
      case GameEndReason.spyGuessedWord:
        return 'خمّن الجاسوس الكلمة الصحيحة';
      case GameEndReason.spyGuessFailed:
        return 'فشل الجاسوس في تخمين الكلمة';
      case GameEndReason.roundLimitReached:
        return 'انتهت الجولات والجاسوس لم يُكشف';
    }
  }

  static String spyCount(int? override) =>
      override == null ? spyCountAuto : '$override';

  static String missingPlayers(int missing) {
    switch (missing) {
      case 1:
        return 'ينقص لاعب واحد على الأقل';
      case 2:
        return 'ينقص لاعبان على الأقل';
      default:
        return 'ينقص $missing لاعبين على الأقل';
    }
  }

  static String failureMessage(RoomFailure failure) {
    switch (failure) {
      case RoomFailure.invalidName:
        return 'اكتب اسمًا من حرف إلى 20 حرفًا';
      case RoomFailure.invalidCode:
        return 'الكود غير صحيح، وهو مكوّن من 6 أحرف وأرقام';
      case RoomFailure.invalidMode:
        return 'وضع اللعب غير مدعوم';
      case RoomFailure.invalidSettings:
        return 'الإعدادات غير صالحة';
      case RoomFailure.roomNotFound:
        return 'لا توجد غرفة بهذا الكود';
      case RoomFailure.roomFull:
        return 'الغرفة ممتلئة';
      case RoomFailure.gameInProgress:
        return 'اللعبة بدأت بالفعل';
      case RoomFailure.nameTaken:
        return 'الاسم مستخدم في هذه الغرفة، اختر اسمًا آخر';
      case RoomFailure.notHost:
        return 'هذا الإجراء للمضيف فقط';
      case RoomFailure.notInRoom:
        return 'لم تعد في هذه الغرفة';
      case RoomFailure.cannotKickSelf:
        return 'لا يمكنك طرد نفسك';
      case RoomFailure.notEnoughPlayers:
        return 'عدد اللاعبين لا يكفي لبدء اللعبة';
      case RoomFailure.noWordsAvailable:
        return 'لا توجد كلمات مناسبة للغة والفئات المختارة';
      case RoomFailure.invalidClue:
        return 'اكتب تلميحًا من حرف إلى 40 حرفًا';
      case RoomFailure.invalidGuess:
        return 'اكتب تخمينًا من حرف إلى 40 حرفًا';
      case RoomFailure.wrongPhase:
        return 'هذا الإجراء غير متاح في هذه المرحلة';
      case RoomFailure.notYourTurn:
        return 'ليس دورك الآن';
      case RoomFailure.alreadyVoted:
        return 'صوتك مسجّل بالفعل';
      case RoomFailure.notAlive:
        return 'أنت خارج اللعبة';
      case RoomFailure.cannotVoteSelf:
        return 'لا يمكنك التصويت لنفسك';
      case RoomFailure.invalidTarget:
        return 'لا يمكن التصويت لهذا اللاعب';
      case RoomFailure.clueRevealsWord:
        return 'لا يمكن أن يكون التلميح هو كلمتك نفسها';
      case RoomFailure.unauthenticated:
        return 'تعذر تسجيل الدخول، حاول مرة أخرى';
      case RoomFailure.network:
        return 'تحقق من الاتصال بالإنترنت ثم حاول مرة أخرى';
      case RoomFailure.unknown:
        return 'حدث خطأ غير متوقع';
    }
  }
}
