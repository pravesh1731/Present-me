import 'package:flutter/services.dart';

class WifiPlatform {
  static const _ch = MethodChannel('com.example.present_me/wifi');

  static Future<bool> isHotspotEnabled() async {
    try {
      final res = await _ch.invokeMethod<bool>('isHotspotEnabled');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openHotspotSettings() async {
    try {
      await _ch.invokeMethod('openHotspotSettings');
    } on PlatformException {
      // ignore
    }
  }

  static Future<String?> getSSID() async {
    try {
      final ssid = await _ch.invokeMethod<String>('getSSID');
      return ssid?.replaceAll('"', '').trim();
    } on PlatformException {
      return null;
    }
  }
}
