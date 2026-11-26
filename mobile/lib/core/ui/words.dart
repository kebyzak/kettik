import 'package:flutter/widgets.dart';

import 'package:kettik/core/domain/auth.dart';
import 'package:kettik/core/domain/game.dart';
import 'package:kettik/core/domain/money.dart';
import 'package:kettik/core/ui/format.dart';
import 'package:kettik/core/ui/theme.dart';
import 'package:kettik/l10n/app_localizations.dart';

// Russian first: Flutter falls back to the first locale for other device languages.
const appLocales = [Locale('ru'), Locale('kk'), Locale('en')];

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

(String, Color) statusWords(AppLocalizations l, Game g) => switch (g.status) {
  GameStatus.funding => (l.statusFunding(hm(g.deadline)), K.signal),
  GameStatus.confirmed => (l.statusConfirmed, K.pitchText),
  GameStatus.expired => (l.statusExpired, K.ink2),
  GameStatus.cancelled => (l.statusCancelled, K.ink2),
};

String rejectionText(AppLocalizations l, Rejection r) => switch (r) {
  Rejection.placeTaken => l.rejectPlaceTaken,
  Rejection.alreadyInGame => l.rejectAlreadyInGame,
  Rejection.fundingClosed => l.rejectFundingClosed,
  Rejection.holdExpired => l.rejectHoldExpired,
  Rejection.notHeld => l.rejectNotHeld,
  Rejection.cannotLeave => l.rejectCannotLeave,
  Rejection.slotTaken => l.rejectSlotTaken,
  Rejection.tooLate => l.rejectTooLate,
  Rejection.offline => l.offline,
  Rejection.failed => l.tryAgain,
};

String refundPromise(AppLocalizations l, Game g, Tenge share) =>
    l.refundPromise(hm(g.deadline), formatTenge(share));

String refundAfterConfirm(AppLocalizations l, Game g) =>
    l.refundAfterConfirm(hm(g.replaceDeadline));

String authRejectionText(AppLocalizations l, AuthRejected e) =>
    switch (e.reason) {
      AuthRejection.badEmail => l.authBadEmail,
      AuthRejection.wrongCode => l.authWrongCode(e.attemptsLeft),
      AuthRejection.codeBurned => l.authCodeBurned,
      AuthRejection.codeExpired => l.authCodeExpired,
      AuthRejection.badName => l.authBadName,
      AuthRejection.tooMany => l.authTooMany,
      AuthRejection.offline => l.offline,
      AuthRejection.failed => l.tryAgain,
    };

String levelName(AppLocalizations l, Level level) => switch (level) {
  Level.casual => l.levelCasual,
  Level.middle => l.levelMiddle,
  Level.strong => l.levelStrong,
};

String formatName(AppLocalizations l, int size, int teams) {
  final side = size ~/ teams;
  if (teams == 3) return l.formatThreeTeams(side);
  if (size.isOdd) return l.formatWithSub(side);
  return '$side×$side';
}
