import 'package:material_ui/material_ui.dart';
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

  Future<void> _check(String code) async {
    try {
      final signedIn = await widget.session.verify(code);
      if (!signedIn && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => NameScreen(session: widget.session),
          ),
        );
      }
    } on AuthRejected catch (e) {
      if (!mounted) return;
      _code.clear();
      setState(() => _error = authRejectionText(context.l10n, e));
    }
  }

  Future<void> _resend() async {
    try {
      final sent = await widget.session.sendCode(widget.email);
      if (!mounted) return;
      _code.clear();
      setState(() {
        _resendAt = sent.resendAt;
        _error = null;
      });
    } on AuthRejected catch (e) {
      if (mounted) setState(() => _error = authRejectionText(context.l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    title: context.l10n.codeTitle,
    lead: context.l10n.codeLead(widget.email, codeLife.inMinutes),
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
                      context.l10n.codeResendIn(countdown(left)),
                      style: body(15, color: K.ink2),
                    ),
                  )
                : PillButton(
                    context.l10n.codeResend,
                    style: PillStyle.quiet,
                    height: 48,
                    onPressed: _resend,
                  );
          },
        ),
        const SizedBox(height: 8),
        RuleLine(context.l10n.codeNoEmail, caveat: true),
      ],
    ),
  );
}
