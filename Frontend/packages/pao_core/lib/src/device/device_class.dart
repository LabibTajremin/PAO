import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Below this much memory an Android phone counts as low-end (P27).
const int lowEndRamMb = 3 * 1024;

/// Whether this is a low-end phone, which gets the light motion set: an
/// Android device that says it is low on RAM or has under 3 GB. Read once at
/// start; an unreadable answer counts as not low-end.
Future<bool> isLowEndDevice({
  Future<AndroidDeviceInfo> Function()? android,
  TargetPlatform? platform,
}) async {
  if (kIsWeb || (platform ?? defaultTargetPlatform) != TargetPlatform.android) {
    return false;
  }
  try {
    final info = await (android ?? _plugin)();
    return info.isLowRamDevice || info.physicalRamSize < lowEndRamMb;
    // Plugins throw platform errors of many types; any of them means unknown.
  } on Object {
    return false;
  }
}

Future<AndroidDeviceInfo> _plugin() => DeviceInfoPlugin().androidInfo;
