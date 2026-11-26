import 'package:flutter/material.dart';

import 'package:kettik/core/data/session.dart';
import 'package:kettik/core/domain/auth.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/core/ui/words.dart';
import 'package:kettik/features/auth/auth_page.dart';
import 'package:kettik/features/auth/code_screen.dart';

/// First step for everyone: one address both signs in and signs up.
class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key, required this.session});

  final Session session;

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _email = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    try {
      final sent = widget.session.sendCode(_email.text, DateTime.now());
      open(
        context,
        CodeScreen(
          session: widget.session,
          email: sent.email,
          resendAt: sent.resendAt,
        ),
      );
    } on AuthRejected catch (e) {
      setState(() => _error = authRejectionText(e));
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    leading: const Back(icon: Icons.close_rounded, tooltip: 'Закрыть'),
    title: 'Вход по почте',
    lead: 'Пришлём код на почту. Если аккаунта ещё нет, создадим его — нужно только имя.',
    field: TextField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.done,
      style: body(17),
      decoration: authField(hint: 'name@mail.kz', error: _error),
      onChanged: (_) => setState(() => _error = null),
      onSubmitted: (_) => _send(),
    ),
    action: PillButton(
      'Получить код',
      onPressed: _email.text.trim().isEmpty ? null : _send,
    ),
  );
}
