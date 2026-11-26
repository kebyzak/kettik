// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get languageName => 'Русский';

  @override
  String get tabGames => 'Игры';

  @override
  String get tabCreate => 'Собрать';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get city => 'Астана';

  @override
  String get back => 'Назад';

  @override
  String get close => 'Закрыть';

  @override
  String get backToGame => 'Вернуться к игре';

  @override
  String get you => 'Вы';

  @override
  String get youShort => 'вы';

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String statusFunding(String time) {
    return 'Идёт сбор · до $time';
  }

  @override
  String get statusConfirmed => 'Игра состоится';

  @override
  String get statusExpired => 'Не собрались — вернём деньги';

  @override
  String get statusCancelled => 'Отменена — вернём деньги';

  @override
  String get rejectPlaceTaken =>
      'Это место только что заняли. Деньги с вас не списаны.';

  @override
  String get rejectAlreadyInGame => 'У вас уже есть место в этой игре.';

  @override
  String get rejectFundingClosed => 'Сбор на эту игру уже закрыт.';

  @override
  String get rejectHoldExpired =>
      'Время на оплату вышло. Если деньги списались, они вернутся автоматически.';

  @override
  String get rejectNotHeld => 'Сначала займите место.';

  @override
  String get rejectCannotLeave => 'Выйти с возвратом уже нельзя.';

  @override
  String refundPromise(String time, String amount) {
    return 'Не соберёмся к $time — вернём $amount полностью.';
  }

  @override
  String refundAfterConfirm(String time) {
    return 'После подтверждения вернём деньги, только если ваше место займут до $time.';
  }

  @override
  String get authBadEmail => 'Проверьте почту: похоже, в адресе опечатка.';

  @override
  String authWrongCode(int count) {
    return 'Неверный код. Осталось попыток: $count.';
  }

  @override
  String get authCodeBurned => 'Код больше не действует. Запросите новый.';

  @override
  String get authCodeExpired => 'Код устарел. Запросите новый.';

  @override
  String get authBadName => 'Имя — от 2 до 40 символов.';

  @override
  String get codeTitle => 'Код из письма';

  @override
  String codeLead(String email, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минуту',
    );
    return 'Отправили на $email. Код действует $_temp0.';
  }

  @override
  String codeResendIn(String time) {
    return 'Новый код через $time';
  }

  @override
  String get codeResend => 'Прислать новый код';

  @override
  String get codeNoEmail => 'Письма нет? Проверьте «Спам» и «Промоакции».';

  @override
  String codeDemo(String code) {
    return 'Демо: код $code';
  }

  @override
  String get emailTitle => 'Вход по почте';

  @override
  String get emailLead =>
      'Пришлём код на почту. Если аккаунта ещё нет, создадим его — нужно только имя.';

  @override
  String get emailGetCode => 'Получить код';

  @override
  String get nameTitle => 'Как вас зовут?';

  @override
  String get nameLead => 'Имя увидят игроки в составе и организатор игры.';

  @override
  String get nameHint => 'Имя и фамилия';

  @override
  String get nameDone => 'Готово';

  @override
  String confirmedSquad(int paid, int size) {
    return '$paid/$size · состав собран';
  }

  @override
  String confirmedLead(String venue, String time) {
    return 'Поле $venue забронировано за вами. Ждём на поле в $time.';
  }

  @override
  String get openTicket => 'Открыть билет';

  @override
  String bannerHolding(int number, String time) {
    return 'Место №$number держим ещё $time';
  }

  @override
  String get pay => 'Оплатить';

  @override
  String paidOf(int paid, int size) {
    return 'Оплатили $paid из $size';
  }

  @override
  String get feedSeeksReplacement => 'ищут замену';

  @override
  String get feedPlacesHeld => 'держат места';

  @override
  String placesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мест',
      few: '$count места',
      one: '$count место',
    );
    return '$_temp0';
  }

  @override
  String get emptyTitle => 'Поле пустое';

  @override
  String get emptyLead =>
      'Пока никто не собирает. Соберите сами — первое место ваше.';

  @override
  String get createGame => 'Собрать игру';

  @override
  String get takeFailedTitle => 'Не получилось занять место';

  @override
  String get pickAnother => 'Выбрать другое место';

  @override
  String get cancelGameQuestion => 'Отменить игру?';

  @override
  String get leaveGameQuestion => 'Выйти из игры?';

  @override
  String get cancelGameBody =>
      'Слот освободится, все оплаты вернутся полностью.';

  @override
  String leaveGameBody(String amount, int number) {
    return 'Вернём $amount полностью. Место №$number займёт кто-то другой.';
  }

  @override
  String get cancelGame => 'Отменить игру';

  @override
  String get leave => 'Выйти';

  @override
  String get stay => 'Остаться';

  @override
  String get paidCaption => 'оплатили';

  @override
  String get lineup => 'Состав';

  @override
  String payPlace(int number, String amount) {
    return 'Оплатить место №$number · $amount';
  }

  @override
  String inSquad(int number) {
    return 'Вы в составе · №$number';
  }

  @override
  String get leaveWithRefund => 'Выйти и вернуть деньги';

  @override
  String takePlace(int number, String amount) {
    return 'Занять №$number · $amount';
  }

  @override
  String get allHeld => 'Все места держат';

  @override
  String get take => 'занять';

  @override
  String get seekingReplacement => 'ищем замену';

  @override
  String insteadOf(String name) {
    return 'вместо $name';
  }

  @override
  String get organizer => 'собирает';

  @override
  String placeYours(int number) {
    return 'Место №$number за вами';
  }

  @override
  String get placeFreed => 'Место освободилось';

  @override
  String get factGame => 'Игра';

  @override
  String get factWhen => 'Когда';

  @override
  String get factRent => 'Аренда';

  @override
  String rentFor(String amount, int size) {
    String _temp0 = intl.Intl.pluralLogic(
      size,
      locale: localeName,
      other: '$size мест',
      few: '$size места',
      one: '$size место',
    );
    return '$amount на $_temp0';
  }

  @override
  String get yourShare => 'Ваша доля';

  @override
  String get alreadyFull => 'Игра уже собрана — оплатите, и место ваше.';

  @override
  String get changeMind => 'Передумаете до подтверждения — деньги вернутся.';

  @override
  String payAmount(String amount) {
    return 'Оплатить $amount';
  }

  @override
  String get payByCard => 'Картой на защищённой странице банка';

  @override
  String get releasePlace => 'Освободить место';

  @override
  String get holdingWhilePay => 'Держим, пока вы платите';

  @override
  String get timeLeft => 'Осталось';

  @override
  String get timeUp => 'Время вышло';

  @override
  String get timeUpBody =>
      'Если деньги успели списаться, они вернутся автоматически.';

  @override
  String get duration60 => '1 час';

  @override
  String get duration90 => '1,5 часа';

  @override
  String get duration120 => '2 часа';

  @override
  String get levelCasual => 'Любители';

  @override
  String get levelMiddle => 'Средний';

  @override
  String get levelStrong => 'Сильный';

  @override
  String formatThreeTeams(int side) {
    return '$side×$side, три команды';
  }

  @override
  String formatWithSub(int side) {
    return '$side×$side с заменой';
  }

  @override
  String pitchOne(String venue) {
    return '$venue · поле 1';
  }

  @override
  String artificialTurf(String address) {
    return '$address · искусственная трава';
  }

  @override
  String startOn(String date) {
    return '$date · начало';
  }

  @override
  String get players => 'Игроков';

  @override
  String firstPlaceYours(String format) {
    return '$format · первое место ваше';
  }

  @override
  String get fewerPlayers => 'Меньше игроков';

  @override
  String get morePlayers => 'Больше игроков';

  @override
  String rentSplit(String amount, int size) {
    return 'Аренда $amount : $size';
  }

  @override
  String fromAmount(String amount) {
    return 'от $amount';
  }

  @override
  String get perPlayer => ' с игрока';

  @override
  String get level => 'Уровень';

  @override
  String fundingClosesAt(String time) {
    return 'Сбор закроется в $time. Не соберёмся — все получат деньги обратно.';
  }

  @override
  String get noSlotsToday => 'На сегодня свободного времени нет';

  @override
  String createAndPay(String amount) {
    return 'Создать и оплатить · $amount';
  }

  @override
  String slotTaken(String time) {
    return '$time, занято';
  }

  @override
  String get myGames => 'Мои игры';

  @override
  String get upcoming => 'Скоро';

  @override
  String get past => 'Прошедшие';

  @override
  String get myGamesEmpty => 'Здесь появятся игры, в которых у вас есть место.';

  @override
  String get account => 'Аккаунт';

  @override
  String get language => 'Язык';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsOn => 'Включены';

  @override
  String get signOut => 'Выйти';

  @override
  String played(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count игроков',
      few: '$count игрока',
      one: '$count игрок',
    );
    return 'Сыграно · $_temp0';
  }

  @override
  String collectingUntil(int paid, int size, String time) {
    return '$paid/$size · сбор до $time';
  }

  @override
  String placeNumber(int number) {
    return 'место №$number';
  }

  @override
  String get signedOutLead =>
      'Войдите, чтобы занимать места, собирать игры и видеть их здесь. Смотреть игры можно и без входа.';

  @override
  String get signInEmail => 'Войти по почте';

  @override
  String get gameRunning => 'Игра идёт';

  @override
  String startsIn(String day, int hours, int minutes) {
    return '$day · через $hours ч $minutes мин';
  }

  @override
  String untilTime(String address, String time) {
    return '$address · до $time';
  }

  @override
  String get cellNumber => 'Номер';

  @override
  String get cellFormat => 'Формат';

  @override
  String get cellPaid => 'Оплачено';

  @override
  String lineupCount(int count) {
    return 'Состав · $count';
  }

  @override
  String replaceSearch(String time, String amount) {
    return 'Ищем вам замену до $time. Займут место — вернём $amount. Не займут — деньги останутся за местом.';
  }

  @override
  String get stayInGame => 'Остаюсь в игре';

  @override
  String get cantCome => 'Не смогу прийти';
}
