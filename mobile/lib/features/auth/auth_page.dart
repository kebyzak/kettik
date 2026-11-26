import 'package:material_ui/material_ui.dart';

import 'package:kettik/core/ui/parts.dart';
import 'package:kettik/core/ui/theme.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.lead,
    required this.field,
    this.footer,
    this.action,
    this.leading = const Back(),
  });

  final String title;
  final String lead;
  final Widget field;
  final Widget? footer;
  final Widget? action;
  final Widget leading;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(4), child: leading),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(title, style: display(28)),
                const SizedBox(height: 8),
                Text(lead, style: body(15, color: K.ink2)),
                const SizedBox(height: 24),
                field,
                if (footer case final f?) ...[const SizedBox(height: 16), f],
              ],
            ),
          ),
          if (action case final a?)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: a,
            ),
        ],
      ),
    ),
  );
}

InputDecoration authField({String? hint, String? error}) {
  OutlineInputBorder edge(Color? color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: color == null
        ? BorderSide.none
        : BorderSide(color: color, width: 2),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: body(17, color: K.dash),
    errorText: error,
    errorStyle: body(13, color: K.danger),
    errorMaxLines: 3,
    filled: true,
    fillColor: K.sheet,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    enabledBorder: edge(null),
    focusedBorder: edge(K.ink),
    errorBorder: edge(K.danger),
    focusedErrorBorder: edge(K.danger),
  );
}
