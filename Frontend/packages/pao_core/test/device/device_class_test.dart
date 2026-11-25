import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

AndroidDeviceInfo _phone({required bool lowRam, required int ramMb}) =>
    AndroidDeviceInfo.setMockInitialValues(
      version: AndroidBuildVersion.setMockInitialValues(
        baseOS: '',
        codename: '',
        incremental: '',
        previewSdkInt: 0,
        release: '14',
        sdkInt: 34,
        securityPatch: '',
      ),
      board: '',
      bootloader: '',
      brand: '',
      device: '',
      display: '',
      fingerprint: '',
      hardware: '',
      host: '',
      id: '',
      manufacturer: '',
      model: '',
      product: '',
      name: '',
      supported32BitAbis: const [],
      supported64BitAbis: const [],
      supportedAbis: const [],
      tags: '',
      time: 0,
      type: '',
      isPhysicalDevice: true,
      freeDiskSize: 0,
      totalDiskSize: 0,
      systemFeatures: const [],
      isLowRamDevice: lowRam,
      physicalRamSize: ramMb,
      availableRamSize: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const android = TargetPlatform.android;

  test('low RAM or under 3 GB on Android is low-end', () async {
    Future<bool> check({required bool lowRam, required int mb}) =>
        isLowEndDevice(
          platform: android,
          android: () async => _phone(lowRam: lowRam, ramMb: mb),
        );
    expect(await check(lowRam: false, mb: 2048), isTrue);
    expect(await check(lowRam: true, mb: 8192), isTrue);
    expect(await check(lowRam: false, mb: 4096), isFalse);
  });

  test('other platforms and unreadable devices are not low-end', () async {
    expect(await isLowEndDevice(platform: TargetPlatform.iOS), isFalse);
    expect(await isLowEndDevice(platform: android), isFalse);
  });
}
