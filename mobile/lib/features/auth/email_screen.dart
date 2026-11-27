import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/data/session.dart';
import 'package:kettik/core/domain/auth.dart';
import 'package:kettik/core/scope.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/core/ui/words.dart';
import 'package:kettik/features/auth/auth_page.dart';
import 'package:kettik/features/auth/code_screen.dart';

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

  Future<void> _send() async {
    try {
      final sent = await widget.session.sendCode(_email.text);
      if (!mounted) return;
      open(
        context,
        CodeScreen(
          session: widget.session,
          email: sent.email,
          resendAt: sent.resendAt,
        ),
      );
    } on AuthRejected catch (e) {
      if (mounted) setState(() => _error = authRejectionText(context.l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    leading: Back(icon: Icons.close_rounded, tooltip: context.l10n.close),
    title: context.l10n.emailTitle,
    lead: context.l10n.emailLead,
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
      context.l10n.emailGetCode,
      onPressed: _email.text.trim().isEmpty ? null : _send,
    ),
  );
}
