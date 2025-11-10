// prefs.dart
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  Prefs._();
  static SharedPreferences? _prefs;
  static final StreamController<String> _changes = StreamController<String>.broadcast();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('Prefs not initialized. Call Prefs.init() first.');
    }
    return p;
  }

  static Stream<String> get changes => _changes.stream;
  static const _metaSuffix = '__meta';

  static String _k(String key, [String? ns]) => ns == null ? key : '$ns::$key';

  // TTL helpers
  static Future<void> _setTTL(String k, Duration? ttl) async {
    if (ttl == null) return;
    final exp = DateTime.now().add(ttl).millisecondsSinceEpoch;
    await _p.setString('$k$_metaSuffix', exp.toString());
  }

  static bool _expired(String k) {
    final expStr = _p.getString('$k$_metaSuffix');
    if (expStr == null) return false;
    final exp = int.tryParse(expStr);
    if (exp == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= exp;
  }

  // Remove/clear
  static Future<bool> remove(String key, {String? namespace}) async {
    final k = _k(key, namespace);
    final ok = await _p.remove(k);
    await _p.remove('$k$_metaSuffix');
    if (ok) _changes.add(k);
    return ok;
  }

  static Future<void> clear({String? namespace}) async {
    if (namespace == null) {
      await _p.clear();
      _changes.add('__all__');
      return;
    }
    final prefix = '$namespace::';
    final keys = _p.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      await _p.remove(k);
      await _p.remove('$k$_metaSuffix');
      _changes.add(k);
    }
  }

  static bool contains(String key, {String? namespace}) {
    final k = _k(key, namespace);
    if (_expired(k)) {
      remove(key, namespace: namespace);
      return false;
    }
    return _p.containsKey(k);
  }

  static Set<String> keys({String? namespace}) {
    final ks = _p.getKeys();
    if (namespace == null) return ks;
    final prefix = '$namespace::';
    return ks.where((k) => k.startsWith(prefix)).toSet();
  }

  static Stream<void> watch(String key, {String? namespace}) =>
      changes.where((k) => k == _k(key, namespace)).map((_) {});

  // Primitives
  static Future<bool> setString(String key, String value, {String? namespace, Duration? ttl}) async {
    final k = _k(key, namespace);
    final ok = await _p.setString(k, value);
    if (ok) {
      await _setTTL(k, ttl);
      _changes.add(k);
    }
    return ok;
  }

  static String? getString(String key, {String? namespace}) {
    final k = _k(key, namespace);
    if (_expired(k)) {
      remove(key, namespace: namespace);
      return null;
    }
    return _p.getString(k);
  }

  static Future<bool> setInt(String key, int value, {String? namespace, Duration? ttl}) async {
    final k = _k(key, namespace);
    final ok = await _p.setInt(k, value);
    if (ok) {
      await _setTTL(k, ttl);
      _changes.add(k);
    }
    return ok;
  }

  static int? getInt(String key, {String? namespace}) {
    final k = _k(key, namespace);
    if (_expired(k)) {
      remove(key, namespace: namespace);
      return null;
    }
    return _p.getInt(k);
  }

  static Future<bool> setBool(String key, bool value, {String? namespace, Duration? ttl}) async {
    final k = _k(key, namespace);
    final ok = await _p.setBool(k, value);
    if (ok) {
      await _setTTL(k, ttl);
      _changes.add(k);
    }
    return ok;
  }

  static bool? getBool(String key, {String? namespace}) {
    final k = _k(key, namespace);
    if (_expired(k)) {
      remove(key, namespace: namespace);
      return null;
    }
    return _p.getBool(k);
  }

  static Future<bool> setDouble(String key, double value, {String? namespace, Duration? ttl}) async {
    final k = _k(key, namespace);
    final ok = await _p.setDouble(k, value);
    if (ok) {
      await _setTTL(k, ttl);
      _changes.add(k);
    }
    return ok;
  }

  static double? getDouble(String key, {String? namespace}) {
    final k = _k(key, namespace);
    if (_expired(k)) {
      remove(key, namespace: namespace);
      return null;
    }
    return _p.getDouble(k);
  }

  static Future<bool> setStringList(String key, List<String> value,
      {String? namespace, Duration? ttl}) async {
    final k = _k(key, namespace);
    final ok = await _p.setStringList(k, value);
    if (ok) {
      await _setTTL(k, ttl);
      _changes.add(k);
    }
    return ok;
  }

  static List<String>? getStringList(String key, {String? namespace}) {
    final k = _k(key, namespace);
    if (_expired(k)) {
      remove(key, namespace: namespace);
      return null;
    }
    return _p.getStringList(k);
  }

  // JSON (Map<String, dynamic>)
  static Future<bool> setJson(String key, Object value,
      {String? namespace, Duration? ttl}) async {
    return setString(key, jsonEncode(value), namespace: namespace, ttl: ttl);
  }

  static Map<String, dynamic>? getJsonMap(String key, {String? namespace}) {
    final s = getString(key, namespace: namespace);
    if (s == null) return null;
    try {
      final v = jsonDecode(s);
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    return null;
  }

  static T? getJsonAs<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap, {
    String? namespace,
  }) {
    final m = getJsonMap(key, namespace: namespace);
    return m == null ? null : fromMap(m);
  }

  // JSON list
  static Future<bool> setJsonList<T>(String key, List<T> list,
      {String? namespace, Duration? ttl}) async {
    return setString(key, jsonEncode(list), namespace: namespace, ttl: ttl);
  }

  static List<E>? getJsonList<E>(
    String key,
    E Function(dynamic) fromJson, {
    String? namespace,
  }) {
    final s = getString(key, namespace: namespace);
    if (s == null) return null;
    try {
      final v = jsonDecode(s);
      if (v is List) {
        return v.map<E>(fromJson).toList();
      }
    } catch (_) {}
    return null;
  }
}
