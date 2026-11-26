import 'package:flutter/foundation.dart';

import 'package:kettik/core/domain/auth.dart';
import 'package:kettik/core/domain/game.dart';

class Session extends ChangeNotifier {
  Session({Map<String, Player> accounts = const {}})
    : _accounts = {...accounts};

  static const demoCode = '123456';

  final Map<String, Player> _accounts;
  Player? _me;
  _Code? _code;
  String? _unnamed;
  var _registered = 0;

  Player? get me => _me;

  ({String email, DateTime resendAt}) sendCode(String raw, DateTime now) {
    final email =
        parseEmail(raw) ?? (throw const AuthRejected(AuthRejection.badEmail));
    final last = _code;
    if (last == null || last.email != email || !now.isBefore(last.resendAt)) {
      _code = _Code(email, now);
    }
    return (email: email, resendAt: _code!.resendAt);
  }

  bool verify(String code, DateTime now) {
    final sent = _code;
    if (sent == null || sent.attemptsLeft == 0) {
      throw const AuthRejected(AuthRejection.codeBurned);
    }
    if (!now.isBefore(sent.sentAt.add(codeLife))) {
      throw const AuthRejected(AuthRejection.codeExpired);
    }
    if (code != demoCode) {
      sent.attemptsLeft--;
      throw AuthRejected(
        sent.attemptsLeft == 0
            ? AuthRejection.codeBurned
            : AuthRejection.wrongCode,
        attemptsLeft: sent.attemptsLeft,
      );
    }
    _code = null;
    final player = _accounts[sent.email];
    if (player == null) {
      _unnamed = sent.email;
      return false;
    }
    _signIn(player);
    return true;
  }

  void register(String raw) {
    final email = _unnamed;
    if (email == null) throw const AuthRejected(AuthRejection.codeBurned);
    final name =
        parseName(raw) ?? (throw const AuthRejected(AuthRejection.badName));
    final player = Player(id: 'u${++_registered}', name: name);
    _accounts[email] = player;
    _unnamed = null;
    _signIn(player);
  }

  void signOut() {
    _me = null;
    notifyListeners();
  }

  void _signIn(Player player) {
    _me = player;
    notifyListeners();
  }
}

class _Code {
  _Code(this.email, this.sentAt);

  final String email;
  final DateTime sentAt;
  var attemptsLeft = codeAttempts;

  DateTime get resendAt => sentAt.add(resendAfter);
}
