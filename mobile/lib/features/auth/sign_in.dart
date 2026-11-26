import 'package:flutter/material.dart';

import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/features/auth/email_screen.dart';

Future<Player?> signIn(BuildContext context) async {
  final scope = AppScope.of(context);
  final session = scope.session;
  if (session.me case final me?) return me;
  final here = ModalRoute.of(context)!;
  final nav = Navigator.of(context);
  void back() {
    if (session.me != null) nav.popUntil((r) => r == here);
  }

  session.addListener(back);
  await nav.push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => EmailScreen(session: session),
    ),
  );
  session.removeListener(back);
  return session.me;
}
