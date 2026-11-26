import 'package:material_ui/material_ui.dart';

import 'package:kettik/app/app.dart';
import 'package:kettik/core/data/api.dart';
import 'package:kettik/core/data/games_store.dart';
import 'package:kettik/core/data/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = Api();
  final session = Session(api);
  final store = GamesStore(api);
  await session.restore();
  // Signing in or out changes which games are the player's.
  session.addListener(store.refresh);
  store.watch();
  runApp(
    KettikApp(
      store: store,
      session: session,
      now: DateTime.now,
      locale: ValueNotifier(null),
    ),
  );
}
