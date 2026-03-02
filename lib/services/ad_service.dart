import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  static const _androidAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  static String get _adUnitId =>
      Platform.isAndroid ? _androidAdUnitId : _iosAdUnitId;

  static const int _minRewardBrains = 500;

  /// Returns 2 hours worth of the player's current brains-per-second income,
  /// always at least [_minRewardBrains] for players who haven't built CPS yet.
  static int computeReward(double cps) {
    final scaled = (cps * 7200).round();
    return scaled > _minRewardBrains ? scaled : _minRewardBrains;
  }

  RewardedAd? _rewardedAd;
  bool _loading = false;

  bool get isAdReady => _rewardedAd != null;
  bool get isLoading => _loading;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  Future<void> loadRewardedAd() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _loading = false;
          notifyListeners();
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    required VoidCallback onFailed,
  }) async {
    if (_rewardedAd == null) {
      onFailed();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        notifyListeners();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        notifyListeners();
        loadRewardedAd();
        onFailed();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => onRewarded(),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}
