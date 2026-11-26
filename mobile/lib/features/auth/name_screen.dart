import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/data/session.dart';
import 'package:kettik/core/domain/auth.dart';
import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/core/ui/words.dart';
import 'package:kettik/features/auth/auth_page.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.session});

  final Session session;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await widget.session.register(_name.text);
    } on AuthRejected catch (e) {
      if (mounted) setState(() => _error = authRejectionText(context.l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    title: context.l10n.nameTitle,
    lead: context.l10n.nameLead,
    field: TextField(
      controller: _name,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      autofillHints: const [AutofillHints.name],
      textInputAction: TextInputAction.done,
      maxLength: 40,
      style: body(17),
      decoration: authField(hint: context.l10n.nameHint, error: _error),
      onChanged: (_) => setState(() => _error = null),
      onSubmitted: (_) => _save(),
    ),
    action: PillButton(
      context.l10n.nameDone,
      onPressed: _name.text.trim().isEmpty ? null : _save,
    ),
  );
}
