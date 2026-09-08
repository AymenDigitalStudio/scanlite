import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String _bannerAdUnitId = 'ca-app-pub-7291352592161789/8728745636';
const String _interstitialAdUnitId = 'ca-app-pub-7291352592161789/2693664799';

class AdService {
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          if (_interstitialLoadAttempts < 3) {
            loadInterstitialAd();
          }
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadInterstitialAd();
          onDismissed?.call();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      onDismissed?.call();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}

BannerAd createBannerAd() {
  final ad = BannerAd(
    adUnitId: _bannerAdUnitId,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
      },
    ),
  )..load();
  return ad;
}
