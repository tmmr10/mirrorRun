import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles in-app review: an explicit "Rate this app" action for the settings
/// screen plus a one-time contextual prompt after the player has completed a
/// few runs. We never incentivize ratings (against App Store / Play policy).
class ReviewService {
  late SharedPreferences _prefs;
  final InAppReview _inAppReview = InAppReview.instance;

  /// Numeric App Store id, needed by [openStoreListing] on iOS. On Android the
  /// plugin resolves the package automatically.
  static const String _iosAppStoreId = '6760182685';

  /// Show the contextual prompt once the player has finished this many runs.
  static const int _promptAfterGames = 5;

  static const String _keyPromptShown = 'rating_prompt_shown';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get _promptShown => _prefs.getBool(_keyPromptShown) ?? false;

  /// Explicit user intent (settings button): jump straight to the store page so
  /// they always land where they can leave a rating.
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(appStoreId: _iosAppStoreId);
    } catch (e) {
      debugPrint('ReviewService.openStoreListing error: $e');
    }
  }

  /// One-time contextual prompt after [_promptAfterGames] completed runs. Uses
  /// the native in-app review sheet; the OS may throttle it, which is fine.
  Future<void> maybeRequestReview({required int totalGames}) async {
    if (_promptShown || totalGames < _promptAfterGames) return;
    await _prefs.setBool(_keyPromptShown, true);
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('ReviewService.maybeRequestReview error: $e');
    }
  }
}
