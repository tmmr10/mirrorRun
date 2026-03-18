import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_service.dart';
import 'skin_service.dart';

class AdService {
  late SharedPreferences _prefs;
  late IapService _iapService;
  SkinService? _skinService;

  int _deathCount = 0;
  bool _isAdFree = false;
  bool _isPro = false;
  DateTime? _lastAdShown;
  bool _firstDeathEver = true;
  InterstitialAd? _interstitialAd;

  bool get isAdFree => _isAdFree;

  /// True if user has Pro (new bundle) OR any legacy purchase.
  bool get isPro => _isPro || _isAdFree || (_skinService?.customSkinUnlocked ?? false);

  /// Debug: force ad after every death
  bool debugAlwaysShowAd = false;

  /// Called when pro status changes (after successful purchase/restore).
  VoidCallback? onProStatusChanged;

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6061884014427414/7321834932';
    } else {
      return 'ca-app-pub-6061884014427414/2229172814';
    }
  }

  Future<void> init({SkinService? skinService}) async {
    _prefs = await SharedPreferences.getInstance();
    _isAdFree = _prefs.getBool('ad_free') ?? false;
    _isPro = _prefs.getBool('is_pro') ?? false;
    _firstDeathEver = _prefs.getBool('first_death_ever') ?? true;
    _skinService = skinService;

    _iapService = IapService();
    await _iapService.init();
    _iapService.onPurchaseResult = _onPurchaseResult;

    if (!isPro) {
      await MobileAds.instance.initialize();
      _loadInterstitialAd();
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
      _prefs.setBool('first_death_ever', false);
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
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onDone();
      },
    );

    _lastAdShown = DateTime.now();
    _interstitialAd!.show();
  }

  Future<bool> purchasePro() async {
    return _iapService.buyPro();
  }

  Future<void> restorePurchases() async {
    await _iapService.restorePurchases();
  }

  void _activatePro() {
    _isPro = true;
    _isAdFree = true;
    _prefs.setBool('is_pro', true);
    _prefs.setBool('ad_free', true);
    _skinService?.setCustomSkinUnlocked(true);
    _interstitialAd?.dispose();
    _interstitialAd = null;
    onProStatusChanged?.call();
  }

  void _onPurchaseResult(String productId, bool success) {
    if (!success) return;

    if (productId == IapService.mirrorRunnersProId) {
      _activatePro();
    } else if (productId == IapService.removeAdsId) {
      _isAdFree = true;
      _prefs.setBool('ad_free', true);
      _interstitialAd?.dispose();
      _interstitialAd = null;
      onProStatusChanged?.call();
    } else if (productId == IapService.customSkinCreatorId) {
      _skinService?.setCustomSkinUnlocked(true);
      onProStatusChanged?.call();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _iapService.dispose();
  }
}
