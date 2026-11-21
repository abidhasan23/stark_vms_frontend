import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class AuthService {
  static const _boxName = 'auth';
  static const _tokenKey = 'token';
  static const _usernameKey = 'username';
  static const _roleKey = 'role';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static Future<void> saveSession({
    required String token,
    required String username,
    required String role,
  }) async {
    await _box.put(_tokenKey, token);
    await _box.put(_usernameKey, username);
    await _box.put(_roleKey, role);
  }

  static Future<void> clearSession() async {
    await _box.deleteAll([_tokenKey, _usernameKey, _roleKey]);
  }

  static bool get isLoggedIn => _box.get(_tokenKey) != null;
  static String? get token => _box.get(_tokenKey);
  static String? get username => _box.get(_usernameKey);
  static String? get role => _box.get(_roleKey);
}
