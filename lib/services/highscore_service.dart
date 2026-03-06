import 'package:shared_preferences/shared_preferences.dart';

class HighscoreService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int getBest() {
    return _prefs.getInt('best_mirror') ?? 0;
  }

  Future<void> saveBest(int score) async {
    await _prefs.setInt('best_mirror', score);
  }

  Future<void> reset() async {
    await _prefs.setInt('best_mirror', 0);
  }
}
