import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:birthday_calendar/features/ads/models/ad_config.dart';
import 'package:birthday_calendar/features/ads/providers/ad_providers.dart';

/// 無料ユーザー時のみ画面下部に表示されるバナー広告ウィジェット。
///
/// - プレミアム会員（`isPremiumProvider == true`）時は即座に `SizedBox.shrink()` となり完全非表示
/// - 広告ロード中・ロード失敗時も不要な空白を残さず静かに非表示
/// - テスト容易性のため [testAdBuilder] を任意で差し替え可能
class AdBannerWidget extends ConsumerStatefulWidget {
  /// Widget テスト用のカスタムバナービルダー（本番コードでは未指定）
  final WidgetBuilder? testAdBuilder;

  /// 画面最下部に直接配置する場合（モーダル下部等）にボトムのSafeAreaを確保するか
  final bool safeAreaBottom;

  const AdBannerWidget({
    super.key,
    this.testAdBuilder,
    this.safeAreaBottom = false,
  });

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _isLoading = false;
  }

  void _loadAdIfNeeded() {
    if (widget.testAdBuilder != null) return;
    if (_bannerAd != null || _isLoading) return;

    final adUnitId = AdConfig.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    _isLoading = true;
    final banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
            _isLoading = false;
          });
        },
      ),
    );

    banner.load();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowAds = ref.watch(shouldShowAdsProvider);

    if (!shouldShowAds) {
      if (_bannerAd != null) {
        _disposeAd();
      }
      return const SizedBox.shrink();
    }

    // テスト用ビルダーが指定されている場合はそのまま描画
    if (widget.testAdBuilder != null) {
      return widget.testAdBuilder!(context);
    }

    // 未ロードならバックグラウンドでロード開始
    if (!_isLoaded && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAdIfNeeded();
        }
      });
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF181818) : Colors.grey.shade100;
    final adHeight = _bannerAd!.size.height.toDouble();
    final adContainer = Container(
      width: double.infinity,
      height: adHeight,
      color: bgColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: adHeight,
        child: AdWidget(ad: _bannerAd!),
      ),
    );

    if (widget.safeAreaBottom) {
      return ColoredBox(
        color: bgColor,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [adContainer],
          ),
        ),
      );
    }

    return adContainer;
  }
}
