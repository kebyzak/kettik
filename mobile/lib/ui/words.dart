import 'package:flutter/painting.dart';

import '../domain/game.dart';
import '../domain/money.dart';
import 'format.dart';
import 'theme.dart';

/// What players read for each server state (see GLOSSARY.md). Players never
/// see HELD or CONFIRMED.
(String, Color) statusWords(Game g) => switch (g.status) {
      GameStatus.funding => ('Идёт сбор · до ${hm(g.deadline)}', K.signal),
      GameStatus.confirmed => ('Игра состоится', K.pitchText),
      GameStatus.expired => ('Не собрались — вернём деньги', K.ink2),
      GameStatus.cancelled => ('Отменена — вернём деньги', K.ink2),
    };

String rejectionText(Rejection r) => switch (r) {
      Rejection.placeTaken => 'Это место только что заняли. Деньги с вас не списаны.',
      Rejection.alreadyInGame => 'У вас уже есть место в этой игре.',
      Rejection.fundingClosed => 'Сбор на эту игру уже закрыт.',
      Rejection.holdExpired => 'Время на оплату вышло. Если деньги списались, они вернутся автоматически.',
      Rejection.notHeld => 'Сначала займите место.',
    };

String refundPromise(Game g, Tenge share) =>
    'Не соберёмся к ${hm(g.deadline)} — вернём ${formatTenge(share)} полностью.';

const noRefundAfterConfirm = 'После подтверждения автоматического возврата нет.';
