import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Remote Config wrapper with safe defaults.
///
/// If Remote Config fails (no internet / timeout / not initialized), this
/// service falls back to the hardcoded defaults in [AppRemoteConfig.defaults].
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  Future<AppRemoteConfig>? _cached;

  Future<AppRemoteConfig> getConfig({bool forceRefresh = false}) {
    if (!forceRefresh && _cached != null) return _cached!;
    _cached = _load();
    return _cached!;
  }

  Future<AppRemoteConfig> _load() async {
    final defaults = AppRemoteConfig.defaults;

    try {
      final rc = FirebaseRemoteConfig.instance;

      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(hours: 6),
        ),
      );

      await rc.setDefaults(defaults.asRemoteDefaults());

      // Remote Config is cached on-device; fetch failures still allow reads.
      try {
        await rc.fetchAndActivate();
      } catch (e) {
        debugPrint('⚠️ [RemoteConfig] fetchAndActivate failed: $e');
      }

      return AppRemoteConfig.fromRemoteConfig(rc, fallback: defaults);
    } catch (e) {
      debugPrint('⚠️ [RemoteConfig] init failed, using defaults: $e');
      return defaults;
    }
  }
}

/// Strongly-typed view over Remote Config parameters.
class AppRemoteConfig {
  final String appVersion;
  final String apiLevel;
  final String targetSdkVersion;
  final String privacyPolicyLink;
  final String orgWebsiteLink;
  final String orgHelpMail;
  final String orgConnectMail;
  final String orgContactNumber;
  final String orgGithubLink;
  final String versionCode;

  const AppRemoteConfig({
    required this.appVersion,
    required this.apiLevel,
    required this.targetSdkVersion,
    required this.privacyPolicyLink,
    required this.orgWebsiteLink,
    required this.orgHelpMail,
    required this.orgConnectMail,
    required this.orgContactNumber,
    required this.orgGithubLink,
    required this.versionCode,
  });

  /// Hardcoded fallback (used when Remote Config is unavailable).
  static const defaults = AppRemoteConfig(
    appVersion: '1.0.0',
    apiLevel: '24',
    targetSdkVersion: '36',
    privacyPolicyLink: 'https://nexiotech.cloud/privacy',
    orgWebsiteLink: 'https://nexiotech.cloud/',
    orgHelpMail: 'help@nexiotech.cloud',
    orgConnectMail: 'connect@nexiotech.cloud',
    orgContactNumber: '7877452256',
    orgGithubLink: 'https://github.com/Nexio-Developer-Group',
    versionCode: '2',
  );

  /// The keys must match your Firebase Remote Config parameter names.
  static const _kAppVersion = 'app_version';
  static const _kApiLevel = 'api_level';
  static const _kTargetSdkVersion = 'target_sdk_version';
  static const _kPrivacyPolicyLink = 'privacy_policy_link';
  static const _kOrgWebsiteLink = 'org_website_link';
  static const _kOrgHelpMail = 'org_help_mail';
  static const _kOrgConnectMail = 'org_connect_mail';
  static const _kOrgContactNumber = 'org_contact_number';
  static const _kOrgGithubLink = 'org_github_link';
  static const _kVersionCode = 'version_code';

  static String _getString(
    FirebaseRemoteConfig rc,
    String key, {
    required String fallback,
  }) {
    final value = rc.getString(key).trim();
    return value.isEmpty ? fallback : value;
  }

  factory AppRemoteConfig.fromRemoteConfig(
    FirebaseRemoteConfig rc, {
    required AppRemoteConfig fallback,
  }) {
    return AppRemoteConfig(
      appVersion: _getString(rc, _kAppVersion, fallback: fallback.appVersion),
      apiLevel: _getString(rc, _kApiLevel, fallback: fallback.apiLevel),
      targetSdkVersion: _getString(
        rc,
        _kTargetSdkVersion,
        fallback: fallback.targetSdkVersion,
      ),
      privacyPolicyLink: _getString(
        rc,
        _kPrivacyPolicyLink,
        fallback: fallback.privacyPolicyLink,
      ),
      orgWebsiteLink: _getString(
        rc,
        _kOrgWebsiteLink,
        fallback: fallback.orgWebsiteLink,
      ),
      orgHelpMail: _getString(
        rc,
        _kOrgHelpMail,
        fallback: fallback.orgHelpMail,
      ),
      orgConnectMail: _getString(
        rc,
        _kOrgConnectMail,
        fallback: fallback.orgConnectMail,
      ),
      orgContactNumber: _getString(
        rc,
        _kOrgContactNumber,
        fallback: fallback.orgContactNumber,
      ),
      orgGithubLink: _getString(
        rc,
        _kOrgGithubLink,
        fallback: fallback.orgGithubLink,
      ),
      versionCode: _getString(
        rc,
        _kVersionCode,
        fallback: fallback.versionCode,
      ),
    );
  }

  Map<String, Object> asRemoteDefaults() {
    return {
      _kAppVersion: appVersion,
      _kApiLevel: apiLevel,
      _kTargetSdkVersion: targetSdkVersion,
      _kPrivacyPolicyLink: privacyPolicyLink,
      _kOrgWebsiteLink: orgWebsiteLink,
      _kOrgHelpMail: orgHelpMail,
      _kOrgConnectMail: orgConnectMail,
      _kOrgContactNumber: orgContactNumber,
      _kOrgGithubLink: orgGithubLink,
      _kVersionCode: versionCode,
    };
  }
}
