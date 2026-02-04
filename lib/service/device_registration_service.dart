import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf_kit/core/constants.dart';
import 'package:pdf_kit/core/utility/storage_utility.dart';
import 'package:pdf_kit/service/remote_config_service.dart';
import 'package:uuid/uuid.dart';

class DeviceRegistrationException implements Exception {
  final String message;
  final Object? cause;

  DeviceRegistrationException(this.message, {this.cause});

  @override
  String toString() =>
      'DeviceRegistrationException(message: $message, cause: $cause)';
}

class DeviceRegistrationService {
  DeviceRegistrationService._();

  static final DeviceRegistrationService instance =
      DeviceRegistrationService._();

  /// Fire-and-forget wrapper meant to be triggered right after onboarding.
  ///
  /// - Never shows UI
  /// - Never throws to caller
  /// - Records non-fatal failures to Crashlytics
  Future<void> syncInBackgroundAfterOnboarding() async {
    final start = DateTime.now();
    try {
      _log('sync start');
      final payload = await _buildPayload();

      _log('payload built', {
        'device_id': payload['device_id'],
        'app_version': payload['app_version'],
        'version_code': payload['version_code'],
        'locale': payload['locale'],
        'os': payload['os'],
        'brand': payload['brand'],
        'manufacturer': payload['manufacturer'],
        'model': payload['model'],
        'android_version': payload['android_version'],
        'sdk_version': payload['sdk_version'],
        'fcm_token': _maskToken(payload['fcm_token']?.toString()),
      });

      // Persist stringified payload locally (even if network fails).
      await Prefs.setString(
        Constants.deviceRegistrationPayloadKey,
        jsonEncode(payload),
      );

      _log('payload stored', {
        'prefs_key': Constants.deviceRegistrationPayloadKey,
        'size_bytes': utf8.encode(jsonEncode(payload)).length,
      });

      await _postPayload(payload);

      _log('sync success', {
        'ms': DateTime.now().difference(start).inMilliseconds,
      });
    } catch (e, st) {
      // "Generate an exception" while ensuring it affects nothing.
      final err = e is DeviceRegistrationException
          ? e
          : DeviceRegistrationException(
              'Device registration sync failed',
              cause: e,
            );

      try {
        await FirebaseCrashlytics.instance.recordError(
          err,
          st,
          fatal: false,
          reason: err.message,
        );
      } catch (_) {
        // Ignore Crashlytics errors too.
      }

      if (kDebugMode) {
        debugPrint(
          '⚠️ [DeviceRegistration] $err (ms: ${DateTime.now().difference(start).inMilliseconds})',
        );
      }
    }
  }

  void _log(String message, [Map<String, Object?> extra = const {}]) {
    if (!kDebugMode) return;
    if (extra.isEmpty) {
      debugPrint('📲 [DeviceRegistration] $message');
      return;
    }
    debugPrint('📲 [DeviceRegistration] $message | ${jsonEncode(extra)}');
  }

  String _maskToken(String? token) {
    if (token == null) return '<null>';
    final t = token.trim();
    if (t.isEmpty) return '<empty>';
    if (t.length <= 10) return '***';
    return '${t.substring(0, 6)}…${t.substring(t.length - 4)}';
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    _log('building payload');
    final config = await RemoteConfigService.instance.getConfig();

    final appVersion = config.appVersion.trim().isNotEmpty
        ? config.appVersion.trim()
        : AppRemoteConfig.defaults.appVersion;

    final versionCode =
        int.tryParse(config.versionCode.trim()) ??
        int.tryParse(AppRemoteConfig.defaults.versionCode) ??
        1;

    final locale = PlatformDispatcher.instance.locale.toLanguageTag();

    final deviceId = _getOrCreateDeviceId();
    _log('device_id resolved', {'device_id': deviceId});

    final fcmToken = await _getFcmToken();
    _log('fcm token acquired', {'fcm_token': _maskToken(fcmToken)});

    final deviceFields = await _getNativeDeviceFields();
    _log('native device fields', deviceFields.map((k, v) => MapEntry(k, v)));

    return {
      'device_id': deviceId,
      'fcm_token': fcmToken,
      'app_version': appVersion,
      'version_code': versionCode,
      'locale': locale,
      ...deviceFields,
    };
  }

  String _getOrCreateDeviceId() {
    final existing = Prefs.getString(Constants.deviceRegistrationPayloadKey);
    if (existing != null) {
      try {
        final decoded = jsonDecode(existing);
        if (decoded is Map && decoded['device_id'] is String) {
          final deviceId = (decoded['device_id'] as String).trim();
          if (deviceId.isNotEmpty) return deviceId;
        }
      } catch (_) {}
    }

    return const Uuid().v4();
  }

  Future<String> _getFcmToken() async {
    try {
      _log('requesting fcm token');
      final messaging = FirebaseMessaging.instance;

      if (Platform.isIOS) {
        // Permission prompt is OS-managed; we never show in-app UI here.
        await messaging.requestPermission();
      }

      final token = await messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        throw DeviceRegistrationException('FCM token is null/empty');
      }
      return token;
    } catch (e) {
      throw DeviceRegistrationException('Failed to obtain FCM token', cause: e);
    }
  }

  Future<Map<String, dynamic>> _getNativeDeviceFields() async {
    final plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return {
        'brand': info.brand,
        'manufacturer': info.manufacturer,
        'model': info.model,
        'android_version': info.version.release,
        'sdk_version': info.version.sdkInt.toString(),
        'os': 'Android',
      };
    }

    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return {
        'brand': 'Apple',
        'manufacturer': 'Apple',
        'model': info.utsname.machine,
        'android_version': info.systemVersion,
        'sdk_version': '0',
        'os': 'iOS',
      };
    }

    // Fallback for desktop/web builds.
    return {
      'brand': 'Unknown',
      'manufacturer': 'Unknown',
      'model': 'Unknown',
      'android_version': '0',
      'sdk_version': '0',
      'os': 'Android',
    };
  }

  Future<void> _postPayload(Map<String, dynamic> payload) async {
    final baseUrl = Constants.deviceRegistrationBaseUrl.trim();

    if (baseUrl.isEmpty) {
      throw DeviceRegistrationException(
        'Constants.deviceRegistrationBaseUrl is empty',
      );
    }

    final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/add_device';
    final uri = Uri.parse(url);

    _log('posting to api', {'url': url});

    final res = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));

    _log('api response', {
      'status': res.statusCode,
      'ok': (res.statusCode == 200 || res.statusCode == 201),
      'body_preview': res.body.length > 400
          ? res.body.substring(0, 400)
          : res.body,
    });

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw DeviceRegistrationException(
        'add_device failed with status ${res.statusCode}',
        cause: res.body,
      );
    }
  }
}
