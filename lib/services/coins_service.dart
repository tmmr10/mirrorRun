import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinsService {
  late SharedPreferences _prefs;
  static const _keyTotal = 'coins_total';

  int _totalCoins = 0;
  int _sessionEarned = 0;
  final ValueNotifier<int> coinsNotifier = ValueNotifier(0);

  int get totalCoins => _totalCoins;
  int get sessionEarned => _sessionEarned;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _totalCoins = _prefs.getInt(_keyTotal) ?? 0;
    coinsNotifier.value = _totalCoins;
  }

  /// Reset per-run counter (call at start of each run).
  void resetSession() => _sessionEarned = 0;

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _totalCoins += amount;
    _sessionEarned += amount;
    coinsNotifier.value = _totalCoins;
    // Awaited (like spendCoins) so earned coins aren't lost on a fast app kill.
    await _prefs.setInt(_keyTotal, _totalCoins);
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (_totalCoins < amount) return false;
    _totalCoins -= amount;
    coinsNotifier.value = _totalCoins;
    await _prefs.setInt(_keyTotal, _totalCoins);
    return true;
  }
}
