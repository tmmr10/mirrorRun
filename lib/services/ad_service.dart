import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'iap_service.dart';
import 'skin_service.dart';

class AdService {
  late SharedPreferences _prefs;
  late IapService _iapService;
  SkinService? _skinService;

  int _deathCount = 1;
  bool _isAdFree = false;
  bool _isPro = false;
  DateTime? _lastAdShown;
  bool _firstDeathEver = true;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _rewardedAdLoading = false;

  // Pro daily-free-revive tracking
  int _proFreeRevivesToday = 0;
  String? _proFreeRevivesLastDate;
  static const int _proFreeRevivesMax = 3;
  static const String _keyProRevivesToday = 'pro_free_revives_today';
  static const String _keyProRevivesLastDate = 'pro_free_revives_date';

  bool get isAdFree => _isAdFree;

  /// True if user has Pro (new bundle) OR any legacy purchase.
  bool get isPro => _isPro || _isAdFree || (_skinService?.customSkinUnlocked ?? false);

  /// Debug: force ad after every death
  bool debugAlwaysShowAd = false;

  /// Notifier that fires when pro status changes (supports multiple listeners).
  /// Value is the current isPro state — notifies only when the bool actually changes.
  final ValueNotifier<bool> proStatusNotifier = ValueNotifier(false);

  void _syncProStatus() {
    proStatusNotifier.value = isPro;
  }

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6061884014427414/7321834932';
    } else {
      return 'ca-app-pub-6061884014427414/2229172814';
    }
  }

  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6061884014427414/2687892649';
    } else {
      return 'ca-app-pub-6061884014427414/9146549274';
    }
  }

  bool get isRewardedAdReady => _rewardedAd != null;

  Future<void> init({SkinService? skinService, IapService? iapService}) async {
    _prefs = await SharedPreferences.getInstance();
    _isAdFree = _prefs.getBool('ad_free') ?? false;
    _isPro = _prefs.getBool('is_pro') ?? false;
    _firstDeathEver = _prefs.getBool('first_death_ever') ?? true;
    // Clamp on load to defend against corrupt prefs
    _proFreeRevivesToday = ((_prefs.getInt(_keyProRevivesToday) ?? 0))
        .clamp(0, _proFreeRevivesMax);
    _proFreeRevivesLastDate = _prefs.getString(_keyProRevivesLastDate);
    _skinService = skinService;

    _iapService = iapService ?? IapService();
    if (iapService == null) await _iapService.init();
    _iapService.onPurchaseResult = _onPurchaseResult;

    _syncProStatus();
    unawaited(AnalyticsService.setProUser(isPro));

    if (!isPro) {
      await MobileAds.instance.initialize();
      _loadInterstitialAd();
      _loadRewardedAd();
    }
  }

  void _loadInterstitialAd() {
    if (isPro) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  bool shouldShowAd(double runDurationSeconds) {
    if (isPro) return false;

    if (debugAlwaysShowAd) return true;

    if (_firstDeathEver) {
      _firstDeathEver = false;
      unawaited(_prefs.setBool('first_death_ever', false));
      unawaited(AnalyticsService.logAdFirstDeathSkipped());
      return false;
    }

    if (runDurationSeconds < 20.0) return false;

    if (_lastAdShown != null &&
        DateTime.now().difference(_lastAdShown!).inSeconds < 120) {
      return false;
    }

    return _deathCount % 3 == 0;
  }

  void onDeath() {
    _deathCount++;
  }

  void showAd(VoidCallback onDone) {
    if (_interstitialAd == null) {
      onDone();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastAdShown = DateTime.now();
        unawaited(AnalyticsService.logAdShown());
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('>>> Ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onDone();
      },
    );

    _interstitialAd!.show();
  }

  /// Localized store price for Pro (e.g. "2,99 €"), or null until loaded.
  String? get proPrice => _iapService.proPrice;

  Future<bool> purchasePro() async {
    return _iapService.buyPro();
  }

  Future<void> restorePurchases() async {
    await _iapService.restorePurchases();
    unawaited(AnalyticsService.logPurchasesRestored());
  }

  Future<void> _activatePro({bool wasRestored = false}) async {
    final wasAlreadyPro = _isPro;
    _isPro = true;
    _isAdFree = true;
    await _prefs.setBool('is_pro', true);
    await _prefs.setBool('ad_free', true);
    await _skinService?.setCustomSkinUnlocked(true);
    // Unlock all preset skins for Pro user
    await _skinService?.unlockAllPresets();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _syncProStatus();
    // Only log purchase once, and distinguish from restore
    if (!wasAlreadyPro) {
      if (wasRestored) {
        unawaited(AnalyticsService.logPurchasesRestored());
      } else {
        unawaited(AnalyticsService.logProPurchased());
      }
      unawaited(AnalyticsService.setProUser(true));
    }
  }

  void _onPurchaseResult(String productId, bool success, bool wasRestored) {
    if (!success) return;

    if (productId == IapService.mirrorRunnersProId) {
      _activatePro(wasRestored: wasRestored);
    } else if (productId == IapService.removeAdsId) {
      final wasAlreadyAdFree = _isAdFree;
      _isAdFree = true;
      unawaited(_prefs.setBool('ad_free', true));
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _syncProStatus();
      if (!wasAlreadyAdFree && !wasRestored) {
        unawaited(AnalyticsService.logProPurchased());
      }
    } else if (productId == IapService.customSkinCreatorId) {
      _skinService?.setCustomSkinUnlocked(true);
      _syncProStatus();
    }
  }

  void _loadRewardedAd() {
    if (isPro || _rewardedAdLoading) return;
    _rewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAdLoading = false;
          debugPrint('>>> Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('>>> Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _rewardedAdLoading = false;
        },
      ),
    );
  }

  /// Shows a rewarded video ad. Calls [onEarnedReward] ONLY if the user
  /// watched the ad to completion. Always calls [onDismissed] at the end
  /// (whether reward was earned or ad was aborted/failed).
  void showRewardedAd({
    required VoidCallback onEarnedReward,
    required VoidCallback onDismissed,
  }) {
    if (_rewardedAd == null) {
      unawaited(AnalyticsService.logRewardedAdFailed());
      onDismissed();
      return;
    }

    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastAdShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (rewardEarned) onEarnedReward();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('>>> Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        unawaited(AnalyticsService.logRewardedAdFailed());
        onDismissed();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      rewardEarned = true;
    });
  }

  // --- Pro Daily Free Revive ---

  /// Returns true if Pro user still has free revives available today.
  /// Pure getter: does NOT perform persistence writes.
  bool canUseFreeProRevive() {
    if (!isPro) return false;
    _refreshDailyReviveStateInMemory();
    return _proFreeRevivesToday < _proFreeRevivesMax;
  }

  /// Remaining free revives today (0..max). 0 for non-Pro users.
  /// Pure getter: does NOT perform persistence writes.
  int getProFreeRevivesRemaining() {
    if (!isPro) return 0;
    _refreshDailyReviveStateInMemory();
    return (_proFreeRevivesMax - _proFreeRevivesToday).clamp(0, _proFreeRevivesMax);
  }

  /// Consume one free revive atomically. Returns true on success, false if
  /// cap already reached or user isn't Pro. Enforces the cap server-side
  /// regardless of stale UI state.
  Future<bool> consumeFreeProRevive() async {
    if (!isPro) return false;
    final today = _formatDateForStorage(DateTime.now());
    final dateChanged = _proFreeRevivesLastDate != today;
    if (dateChanged) {
      _proFreeRevivesToday = 0;
      _proFreeRevivesLastDate = today;
    }
    if (_proFreeRevivesToday >= _proFreeRevivesMax) {
      // Persist the date-reset even if cap hit (unlikely but keeps state consistent)
      if (dateChanged) {
        await _prefs.setString(_keyProRevivesLastDate, today);
        await _prefs.setInt(_keyProRevivesToday, 0);
      }
      return false;
    }
    _proFreeRevivesToday++;
    if (dateChanged) {
      await _prefs.setString(_keyProRevivesLastDate, today);
    }
    await _prefs.setInt(_keyProRevivesToday, _proFreeRevivesToday);
    return true;
  }

  /// Updates in-memory counter if the date has rolled over. Does NOT write
  /// to prefs — defers persistence to the next consume/explicit-refresh call.
  void _refreshDailyReviveStateInMemory() {
    final today = _formatDateForStorage(DateTime.now());
    if (_proFreeRevivesLastDate != today) {
      _proFreeRevivesToday = 0;
      // Note: lastDate is NOT updated here — we defer the write until we actually
      // need to persist. This prevents fire-and-forget writes on every UI rebuild.
    }
  }

  static String _formatDateForStorage(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _iapService.dispose();
  }
}
