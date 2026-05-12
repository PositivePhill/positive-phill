import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;

  // TEST AD UNIT IDs (for development)
  // Replace with your real AdMob unit IDs for production
  static String get rewardedAdUnitId {
    if (kIsWeb) return 'web-disabled';
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (kDebugMode) {
      return isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    // TODO: Replace with your production ad unit IDs before publishing
    return isAndroid
        ? 'ca-app-pub-3940256099942544/5224354917'
        : 'ca-app-pub-3940256099942544/1712485313';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return 'web-disabled';
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (kDebugMode) {
      return isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    // TODO: Replace with your production ad unit IDs before publishing
    return isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
    }
  }

  void loadRewardedAd() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: $error');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAd(Function(int amount) onUserEarnedReward) async {
    if (kIsWeb) return false;
    if (!_isRewardedAdReady || _rewardedAd == null) return false;

    final ad = _rewardedAd!;
    final completer = Completer<bool>();
    var rewardReported = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissed) {
        dismissed.dispose();
        _isRewardedAdReady = false;
        loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(rewardReported);
        }
      },
      onAdFailedToShowFullScreenContent: (failed, error) {
        debugPrint('Rewarded ad failed to show: $error');
        failed.dispose();
        _isRewardedAdReady = false;
        loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    _isRewardedAdReady = false;

    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          rewardReported = true;
          onUserEarnedReward(reward.amount.toInt());
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );
    } catch (e) {
      debugPrint('Rewarded ad show error: $e');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      _isRewardedAdReady = false;
      loadRewardedAd();
      return false;
    }

    return completer.future;
  }

  void loadInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: $error');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (kIsWeb) return;
    if (!_isInterstitialAdReady || _interstitialAd == null) return;

    await _interstitialAd?.show();
    _isInterstitialAdReady = false;
  }

  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }
}
