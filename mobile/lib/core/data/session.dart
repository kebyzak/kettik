import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kettik/core/data/api.dart';
import 'package:kettik/core/domain/auth.dart';
import 'package:kettik/core/domain/game.dart';

class Session extends ChangeNotifier {
  Session(this._api, [this._storage = const FlutterSecureStorage()]);

  static const _tokenKey = 'token';

  final Api _api;
  final FlutterSecureStorage _storage;
  Player? _me;
  String? _email;

  Player? get me => _me;

  /// Signs back in with the saved token, if it still works.
  Future<void> restore() async {
    _api.token = await _storage.read(key: _tokenKey);
    if (_api.token == null) return;
    try {
      final player = _player(await _api.get('/me'));
      if (player == null) return await _forget();
      _signIn(player);
    } on ApiError catch (e) {
      // shortcut: offline at launch starts signed out but keeps the token; retry /me on reconnect if that bothers players.
      if (e.status == 401) await _forget();
    }
  }

  Future<({String email, DateTime resendAt})> sendCode(String raw) async {
    final email =
        parseEmail(raw) ?? (throw const AuthRejected(AuthRejection.badEmail));
    await _call(() => _api.post('/auth/code', {'email': email}));
    _email = email;
    // Within the server's resend window a repeat request sends nothing.
    return (email: email, resendAt: DateTime.now().add(resendAfter));
  }

  /// True when signed in; false when the player still has to give a name.
  Future<bool> verify(String code) async {
    final email = _email;
    if (email == null) throw const AuthRejected(AuthRejection.codeBurned);
    final res = await _call(
      () => _api.post('/auth/verify', {'email': email, 'code': code}),
    ) as Map<String, Object?>;
    _api.token = res['token'] as String;
    await _storage.write(key: _tokenKey, value: _api.token);
    final player = _player(res['player']);
    if (player == null) return false;
    _signIn(player);
    return true;
  }

  Future<void> register(String raw) async {
    final name =
        parseName(raw) ?? (throw const AuthRejected(AuthRejection.badName));
    final player = _player(await _call(() => _api.post('/me', {'name': name})));
    _signIn(player!);
  }

  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout');
    } on ApiError {
      // The token is dropped here either way; the server one expires unused.
    }
    await _forget();
    _me = null;
    notifyListeners();
  }

  Future<void> _forget() async {
    _api.token = null;
    await _storage.delete(key: _tokenKey);
  }

  void _signIn(Player player) {
    _me = player;
    notifyListeners();
  }

  Future<Object?> _call(Future<Object?> Function() request) async {
    try {
      return await request();
    } on ApiError catch (e) {
      throw AuthRejected(
        _rejections[e.reason] ?? AuthRejection.failed,
        attemptsLeft: e.body['attemptsLeft'] as int? ?? 0,
      );
    }
  }
}

const _rejections = {
  'bad_email': AuthRejection.badEmail,
  'wrong_code': AuthRejection.wrongCode,
  'code_burned': AuthRejection.codeBurned,
  'code_expired': AuthRejection.codeExpired,
  'bad_name': AuthRejection.badName,
  'too_many': AuthRejection.tooMany,
  'offline': AuthRejection.offline,
};

Player? _player(Object? json) => switch (json) {
  {'id': final String id, 'name': final String name} => Player(
    id: id,
    name: name,
  ),
  _ => null,
};
