import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static const String _adUnitIdAndroid = 'ca-app-pub-8500075420783419/7744204780';
  static const String _adUnitIdIOS = 'ca-app-pub-3940256099942544/3986624511';

  static String get adUnitId {
    if (Platform.isAndroid) {
      return _adUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _adUnitIdIOS;
    }
    return '';
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static NativeAd createNativeAd({
    required NativeAdListener listener,
    NativeTemplateStyle? nativeTemplateStyle,
  }) {
    return NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: listener,
      nativeTemplateStyle: nativeTemplateStyle ?? defaultNativeTemplateStyle,
    );
  }

  static NativeTemplateStyle get defaultNativeTemplateStyle {
    return NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: Colors.transparent,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: const Color(0xFF00478D),
        style: NativeTemplateFontStyle.normal,
        size: 14.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.black87,
        style: NativeTemplateFontStyle.bold,
        size: 16.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.black54,
        style: NativeTemplateFontStyle.normal,
        size: 14.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.black45,
        style: NativeTemplateFontStyle.italic,
        size: 12.0,
      ),
    );
  }
}