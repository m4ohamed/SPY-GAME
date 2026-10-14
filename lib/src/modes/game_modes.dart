import '../enums.dart';
import 'game_mode.dart';
import 'imposter_mode.dart';
import 'undercover_mode.dart';

/// Lookup of every game mode. Add new modes here.
abstract final class GameModes {
  static const UndercoverMode undercover = UndercoverMode();
  static const ImposterMode imposter = ImposterMode();

  static const List<GameMode> all = [undercover, imposter];

  static GameMode of(GameModeType type) {
    switch (type) {
      case GameModeType.undercover:
        return undercover;
      case GameModeType.imposter:
        return imposter;
    }
  }
}
