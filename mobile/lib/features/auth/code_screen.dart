import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kettik/core/data/session.dart';
import 'package:kettik/core/domain/auth.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/core/ui/words.dart';
import 'package:kettik/features/auth/auth_page.dart';
import 'package:kettik/features/auth/name_screen.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({
    super.key,
    required this.session,
    required this.email,
    required this.resendAt,
  });

  final Session session;
  final String email;
  final DateTime resendAt;

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final _code = TextEditingController();
  late var _resendAt = widget.resendAt;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _check(String code) {
    try {
      if (!widget.session.verify(code, DateTime.now())) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => NameScreen(session: widget.session),
          ),
        );
      }
    } on AuthRejected catch (e) {
      _code.clear();
      setState(() => _error = authRejectionText(e));
    }
  }

  void _resend() {
    final sent = widget.session.sendCode(widget.email, DateTime.now());
    _code.clear();
    setState(() {
      _resendAt = sent.resendAt;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    title: 'Код из письма',
    lead:
        'Отправили на ${widget.email}. Код действует ${codeLife.inMinutes} минут.',
    field: TextField(
      controller: _code,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 6,
      autofillHints: const [AutofillHints.oneTimeCode],
      textAlign: TextAlign.center,
      style: display(28).copyWith(letterSpacing: 12),
      decoration: authField(hint: '••••••', error: _error),
      onChanged: (v) {
        if (_error != null) setState(() => _error = null);
        if (v.length == 6) _check(v);
      },
    ),
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EverySecond(
          builder: (context) {
            final left = _resendAt.difference(DateTime.now());
            return left > Duration.zero
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Новый код через ${countdown(left)}',
                      style: body(15, color: K.ink2),
                    ),
                  )
                : PillButton(
                    'Прислать новый код',
                    style: PillStyle.quiet,
                    height: 48,
                    onPressed: _resend,
                  );
          },
        ),
        const SizedBox(height: 8),
        const RuleLine(
          'Письма нет? Проверьте «Спам» и «Промоакции».',
          caveat: true,
        ),
        const SizedBox(height: 8),
        const RuleLine('Демо: код ${Session.demoCode}', caveat: true),
      ],
    ),
  );
}
