import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @languageName.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageName;

  /// No description provided for @tabGames.
  ///
  /// In ru, this message translates to:
  /// **'Игры'**
  String get tabGames;

  /// No description provided for @tabCreate.
  ///
  /// In ru, this message translates to:
  /// **'Собрать'**
  String get tabCreate;

  /// No description provided for @tabProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get tabProfile;

  /// No description provided for @city.
  ///
  /// In ru, this message translates to:
  /// **'Астана'**
  String get city;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @backToGame.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к игре'**
  String get backToGame;

  /// No description provided for @you.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get you;

  /// No description provided for @youShort.
  ///
  /// In ru, this message translates to:
  /// **'вы'**
  String get youShort;

  /// No description provided for @today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Завтра'**
  String get tomorrow;

  /// No description provided for @statusFunding.
  ///
  /// In ru, this message translates to:
  /// **'Идёт сбор · до {time}'**
  String statusFunding(String time);

  /// No description provided for @statusConfirmed.
  ///
  /// In ru, this message translates to:
  /// **'Игра состоится'**
  String get statusConfirmed;

  /// No description provided for @statusExpired.
  ///
  /// In ru, this message translates to:
  /// **'Не собрались — вернём деньги'**
  String get statusExpired;

  /// No description provided for @statusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменена — вернём деньги'**
  String get statusCancelled;

  /// No description provided for @rejectPlaceTaken.
  ///
  /// In ru, this message translates to:
  /// **'Это место только что заняли. Деньги с вас не списаны.'**
  String get rejectPlaceTaken;

  /// No description provided for @rejectAlreadyInGame.
  ///
  /// In ru, this message translates to:
  /// **'У вас уже есть место в этой игре.'**
  String get rejectAlreadyInGame;

  /// No description provided for @rejectFundingClosed.
  ///
  /// In ru, this message translates to:
  /// **'Сбор на эту игру уже закрыт.'**
  String get rejectFundingClosed;

  /// No description provided for @rejectHoldExpired.
  ///
  /// In ru, this message translates to:
  /// **'Время на оплату вышло. Если деньги списались, они вернутся автоматически.'**
  String get rejectHoldExpired;

  /// No description provided for @rejectNotHeld.
  ///
  /// In ru, this message translates to:
  /// **'Сначала займите место.'**
  String get rejectNotHeld;

  /// No description provided for @rejectCannotLeave.
  ///
  /// In ru, this message translates to:
  /// **'Выйти с возвратом уже нельзя.'**
  String get rejectCannotLeave;

  /// No description provided for @rejectSlotTaken.
  ///
  /// In ru, this message translates to:
  /// **'Это время уже заняли. Выберите другое.'**
  String get rejectSlotTaken;

  /// No description provided for @rejectTooLate.
  ///
  /// In ru, this message translates to:
  /// **'На это время уже не успеть собрать игру.'**
  String get rejectTooLate;

  /// No description provided for @offline.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером. Проверьте интернет.'**
  String get offline;

  /// No description provided for @tryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Не получилось. Попробуйте ещё раз.'**
  String get tryAgain;

  /// No description provided for @tryAgainShort.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get tryAgainShort;

  /// No description provided for @authTooMany.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много запросов. Попробуйте через час.'**
  String get authTooMany;

  /// No description provided for @refundPromise.
  ///
  /// In ru, this message translates to:
  /// **'Не соберёмся к {time} — вернём {amount} полностью.'**
  String refundPromise(String time, String amount);

  /// No description provided for @refundAfterConfirm.
  ///
  /// In ru, this message translates to:
  /// **'После подтверждения вернём деньги, только если ваше место займут до {time}.'**
  String refundAfterConfirm(String time);

  /// No description provided for @authBadEmail.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте почту: похоже, в адресе опечатка.'**
  String get authBadEmail;

  /// No description provided for @authWrongCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код. Осталось попыток: {count}.'**
  String authWrongCode(int count);

  /// No description provided for @authCodeBurned.
  ///
  /// In ru, this message translates to:
  /// **'Код больше не действует. Запросите новый.'**
  String get authCodeBurned;

  /// No description provided for @authCodeExpired.
  ///
  /// In ru, this message translates to:
  /// **'Код устарел. Запросите новый.'**
  String get authCodeExpired;

  /// No description provided for @authBadName.
  ///
  /// In ru, this message translates to:
  /// **'Имя — от 2 до 40 символов.'**
  String get authBadName;

  /// No description provided for @codeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Код из письма'**
  String get codeTitle;

  /// No description provided for @codeLead.
  ///
  /// In ru, this message translates to:
  /// **'Отправили на {email}. Код действует {minutes, plural, one{{minutes} минуту} few{{minutes} минуты} other{{minutes} минут}}.'**
  String codeLead(String email, int minutes);

  /// No description provided for @codeResendIn.
  ///
  /// In ru, this message translates to:
  /// **'Новый код через {time}'**
  String codeResendIn(String time);

  /// No description provided for @codeResend.
  ///
  /// In ru, this message translates to:
  /// **'Прислать новый код'**
  String get codeResend;

  /// No description provided for @codeNoEmail.
  ///
  /// In ru, this message translates to:
  /// **'Письма нет? Проверьте «Спам» и «Промоакции».'**
  String get codeNoEmail;

  /// No description provided for @emailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход по почте'**
  String get emailTitle;

  /// No description provided for @emailLead.
  ///
  /// In ru, this message translates to:
  /// **'Пришлём код на почту. Если аккаунта ещё нет, создадим его — нужно только имя.'**
  String get emailLead;

  /// No description provided for @emailGetCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get emailGetCode;

  /// No description provided for @nameTitle.
  ///
  /// In ru, this message translates to:
  /// **'Как вас зовут?'**
  String get nameTitle;

  /// No description provided for @nameLead.
  ///
  /// In ru, this message translates to:
  /// **'Имя увидят игроки в составе и организатор игры.'**
  String get nameLead;

  /// No description provided for @nameHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя и фамилия'**
  String get nameHint;

  /// No description provided for @nameDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get nameDone;

  /// No description provided for @confirmedSquad.
  ///
  /// In ru, this message translates to:
  /// **'{paid}/{size} · состав собран'**
  String confirmedSquad(int paid, int size);

  /// No description provided for @confirmedLead.
  ///
  /// In ru, this message translates to:
  /// **'Поле {venue} забронировано за вами. Ждём на поле в {time}.'**
  String confirmedLead(String venue, String time);

  /// No description provided for @openTicket.
  ///
  /// In ru, this message translates to:
  /// **'Открыть билет'**
  String get openTicket;

  /// No description provided for @bannerHolding.
  ///
  /// In ru, this message translates to:
  /// **'Место №{number} держим ещё {time}'**
  String bannerHolding(int number, String time);

  /// No description provided for @pay.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить'**
  String get pay;

  /// No description provided for @paidOf.
  ///
  /// In ru, this message translates to:
  /// **'Оплатили {paid} из {size}'**
  String paidOf(int paid, int size);

  /// No description provided for @feedSeeksReplacement.
  ///
  /// In ru, this message translates to:
  /// **'ищут замену'**
  String get feedSeeksReplacement;

  /// No description provided for @feedPlacesHeld.
  ///
  /// In ru, this message translates to:
  /// **'держат места'**
  String get feedPlacesHeld;

  /// No description provided for @placesLeft.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} место} few{{count} места} other{{count} мест}}'**
  String placesLeft(int count);

  /// No description provided for @emptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поле пустое'**
  String get emptyTitle;

  /// No description provided for @emptyLead.
  ///
  /// In ru, this message translates to:
  /// **'Пока никто не собирает. Соберите сами — первое место ваше.'**
  String get emptyLead;

  /// No description provided for @createGame.
  ///
  /// In ru, this message translates to:
  /// **'Собрать игру'**
  String get createGame;

  /// No description provided for @takeFailedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не получилось занять место'**
  String get takeFailedTitle;

  /// No description provided for @pickAnother.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать другое место'**
  String get pickAnother;

  /// No description provided for @cancelGameQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Отменить игру?'**
  String get cancelGameQuestion;

  /// No description provided for @leaveGameQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из игры?'**
  String get leaveGameQuestion;

  /// No description provided for @cancelGameBody.
  ///
  /// In ru, this message translates to:
  /// **'Слот освободится, все оплаты вернутся полностью.'**
  String get cancelGameBody;

  /// No description provided for @leaveGameBody.
  ///
  /// In ru, this message translates to:
  /// **'Вернём {amount} полностью. Место №{number} займёт кто-то другой.'**
  String leaveGameBody(String amount, int number);

  /// No description provided for @cancelGame.
  ///
  /// In ru, this message translates to:
  /// **'Отменить игру'**
  String get cancelGame;

  /// No description provided for @leave.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get leave;

  /// No description provided for @stay.
  ///
  /// In ru, this message translates to:
  /// **'Остаться'**
  String get stay;

  /// No description provided for @paidCaption.
  ///
  /// In ru, this message translates to:
  /// **'оплатили'**
  String get paidCaption;

  /// No description provided for @lineup.
  ///
  /// In ru, this message translates to:
  /// **'Состав'**
  String get lineup;

  /// No description provided for @payPlace.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить место №{number} · {amount}'**
  String payPlace(int number, String amount);

  /// No description provided for @inSquad.
  ///
  /// In ru, this message translates to:
  /// **'Вы в составе · №{number}'**
  String inSquad(int number);

  /// No description provided for @leaveWithRefund.
  ///
  /// In ru, this message translates to:
  /// **'Выйти и вернуть деньги'**
  String get leaveWithRefund;

  /// No description provided for @takePlace.
  ///
  /// In ru, this message translates to:
  /// **'Занять №{number} · {amount}'**
  String takePlace(int number, String amount);

  /// No description provided for @allHeld.
  ///
  /// In ru, this message translates to:
  /// **'Все места держат'**
  String get allHeld;

  /// No description provided for @take.
  ///
  /// In ru, this message translates to:
  /// **'занять'**
  String get take;

  /// No description provided for @seekingReplacement.
  ///
  /// In ru, this message translates to:
  /// **'ищем замену'**
  String get seekingReplacement;

  /// No description provided for @insteadOf.
  ///
  /// In ru, this message translates to:
  /// **'вместо {name}'**
  String insteadOf(String name);

  /// No description provided for @organizer.
  ///
  /// In ru, this message translates to:
  /// **'собирает'**
  String get organizer;

  /// No description provided for @placeYours.
  ///
  /// In ru, this message translates to:
  /// **'Место №{number} за вами'**
  String placeYours(int number);

  /// No description provided for @placeFreed.
  ///
  /// In ru, this message translates to:
  /// **'Место освободилось'**
  String get placeFreed;

  /// No description provided for @factGame.
  ///
  /// In ru, this message translates to:
  /// **'Игра'**
  String get factGame;

  /// No description provided for @factWhen.
  ///
  /// In ru, this message translates to:
  /// **'Когда'**
  String get factWhen;

  /// No description provided for @factRent.
  ///
  /// In ru, this message translates to:
  /// **'Аренда'**
  String get factRent;

  /// No description provided for @rentFor.
  ///
  /// In ru, this message translates to:
  /// **'{amount} на {size, plural, one{{size} место} few{{size} места} other{{size} мест}}'**
  String rentFor(String amount, int size);

  /// No description provided for @yourShare.
  ///
  /// In ru, this message translates to:
  /// **'Ваша доля'**
  String get yourShare;

  /// No description provided for @alreadyFull.
  ///
  /// In ru, this message translates to:
  /// **'Игра уже собрана — оплатите, и место ваше.'**
  String get alreadyFull;

  /// No description provided for @changeMind.
  ///
  /// In ru, this message translates to:
  /// **'Передумаете до подтверждения — деньги вернутся.'**
  String get changeMind;

  /// No description provided for @payAmount.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить {amount}'**
  String payAmount(String amount);

  /// No description provided for @payByCard.
  ///
  /// In ru, this message translates to:
  /// **'Картой на защищённой странице банка'**
  String get payByCard;

  /// No description provided for @releasePlace.
  ///
  /// In ru, this message translates to:
  /// **'Освободить место'**
  String get releasePlace;

  /// No description provided for @holdingWhilePay.
  ///
  /// In ru, this message translates to:
  /// **'Держим, пока вы платите'**
  String get holdingWhilePay;

  /// No description provided for @timeLeft.
  ///
  /// In ru, this message translates to:
  /// **'Осталось'**
  String get timeLeft;

  /// No description provided for @timeUp.
  ///
  /// In ru, this message translates to:
  /// **'Время вышло'**
  String get timeUp;

  /// No description provided for @timeUpBody.
  ///
  /// In ru, this message translates to:
  /// **'Если деньги успели списаться, они вернутся автоматически.'**
  String get timeUpBody;

  /// No description provided for @duration60.
  ///
  /// In ru, this message translates to:
  /// **'1 час'**
  String get duration60;

  /// No description provided for @duration90.
  ///
  /// In ru, this message translates to:
  /// **'1,5 часа'**
  String get duration90;

  /// No description provided for @duration120.
  ///
  /// In ru, this message translates to:
  /// **'2 часа'**
  String get duration120;

  /// No description provided for @levelCasual.
  ///
  /// In ru, this message translates to:
  /// **'Любители'**
  String get levelCasual;

  /// No description provided for @levelMiddle.
  ///
  /// In ru, this message translates to:
  /// **'Средний'**
  String get levelMiddle;

  /// No description provided for @levelStrong.
  ///
  /// In ru, this message translates to:
  /// **'Сильный'**
  String get levelStrong;

  /// No description provided for @formatThreeTeams.
  ///
  /// In ru, this message translates to:
  /// **'{side}×{side}, три команды'**
  String formatThreeTeams(int side);

  /// No description provided for @formatWithSub.
  ///
  /// In ru, this message translates to:
  /// **'{side}×{side} с заменой'**
  String formatWithSub(int side);

  /// No description provided for @pitchOne.
  ///
  /// In ru, this message translates to:
  /// **'{venue} · поле 1'**
  String pitchOne(String venue);

  /// No description provided for @artificialTurf.
  ///
  /// In ru, this message translates to:
  /// **'{address} · искусственная трава'**
  String artificialTurf(String address);

  /// No description provided for @startOn.
  ///
  /// In ru, this message translates to:
  /// **'{date} · начало'**
  String startOn(String date);

  /// No description provided for @players.
  ///
  /// In ru, this message translates to:
  /// **'Игроков'**
  String get players;

  /// No description provided for @firstPlaceYours.
  ///
  /// In ru, this message translates to:
  /// **'{format} · первое место ваше'**
  String firstPlaceYours(String format);

  /// No description provided for @fewerPlayers.
  ///
  /// In ru, this message translates to:
  /// **'Меньше игроков'**
  String get fewerPlayers;

  /// No description provided for @morePlayers.
  ///
  /// In ru, this message translates to:
  /// **'Больше игроков'**
  String get morePlayers;

  /// No description provided for @rentSplit.
  ///
  /// In ru, this message translates to:
  /// **'Аренда {amount} : {size}'**
  String rentSplit(String amount, int size);

  /// No description provided for @fromAmount.
  ///
  /// In ru, this message translates to:
  /// **'от {amount}'**
  String fromAmount(String amount);

  /// No description provided for @perPlayer.
  ///
  /// In ru, this message translates to:
  /// **' с игрока'**
  String get perPlayer;

  /// No description provided for @level.
  ///
  /// In ru, this message translates to:
  /// **'Уровень'**
  String get level;

  /// No description provided for @fundingClosesAt.
  ///
  /// In ru, this message translates to:
  /// **'Сбор закроется в {time}. Не соберёмся — все получат деньги обратно.'**
  String fundingClosesAt(String time);

  /// No description provided for @noSlotsToday.
  ///
  /// In ru, this message translates to:
  /// **'В этот день свободного времени нет'**
  String get noSlotsToday;

  /// No description provided for @noVenues.
  ///
  /// In ru, this message translates to:
  /// **'Площадок пока нет. Скоро появятся'**
  String get noVenues;

  /// No description provided for @createAndPay.
  ///
  /// In ru, this message translates to:
  /// **'Создать и оплатить · {amount}'**
  String createAndPay(String amount);

  /// No description provided for @slotTaken.
  ///
  /// In ru, this message translates to:
  /// **'{time}, занято'**
  String slotTaken(String time);

  /// No description provided for @myGames.
  ///
  /// In ru, this message translates to:
  /// **'Мои игры'**
  String get myGames;

  /// No description provided for @upcoming.
  ///
  /// In ru, this message translates to:
  /// **'Скоро'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In ru, this message translates to:
  /// **'Прошедшие'**
  String get past;

  /// No description provided for @myGamesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся игры, в которых у вас есть место.'**
  String get myGamesEmpty;

  /// No description provided for @account.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get account;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @notificationsOn.
  ///
  /// In ru, this message translates to:
  /// **'Включены'**
  String get notificationsOn;

  /// No description provided for @signOut.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get signOut;

  /// No description provided for @played.
  ///
  /// In ru, this message translates to:
  /// **'Сыграно · {count, plural, one{{count} игрок} few{{count} игрока} other{{count} игроков}}'**
  String played(int count);

  /// No description provided for @collectingUntil.
  ///
  /// In ru, this message translates to:
  /// **'{paid}/{size} · сбор до {time}'**
  String collectingUntil(int paid, int size, String time);

  /// No description provided for @placeNumber.
  ///
  /// In ru, this message translates to:
  /// **'место №{number}'**
  String placeNumber(int number);

  /// No description provided for @signedOutLead.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы занимать места, собирать игры и видеть их здесь. Смотреть игры можно и без входа.'**
  String get signedOutLead;

  /// No description provided for @signInEmail.
  ///
  /// In ru, this message translates to:
  /// **'Войти по почте'**
  String get signInEmail;

  /// No description provided for @gameRunning.
  ///
  /// In ru, this message translates to:
  /// **'Игра идёт'**
  String get gameRunning;

  /// No description provided for @startsIn.
  ///
  /// In ru, this message translates to:
  /// **'{day} · через {hours} ч {minutes} мин'**
  String startsIn(String day, int hours, int minutes);

  /// No description provided for @untilTime.
  ///
  /// In ru, this message translates to:
  /// **'{address} · до {time}'**
  String untilTime(String address, String time);

  /// No description provided for @cellNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер'**
  String get cellNumber;

  /// No description provided for @cellFormat.
  ///
  /// In ru, this message translates to:
  /// **'Формат'**
  String get cellFormat;

  /// No description provided for @cellPaid.
  ///
  /// In ru, this message translates to:
  /// **'Оплачено'**
  String get cellPaid;

  /// No description provided for @lineupCount.
  ///
  /// In ru, this message translates to:
  /// **'Состав · {count}'**
  String lineupCount(int count);

  /// No description provided for @replaceSearch.
  ///
  /// In ru, this message translates to:
  /// **'Ищем вам замену до {time}. Займут место — вернём {amount}. Не займут — деньги останутся за местом.'**
  String replaceSearch(String time, String amount);

  /// No description provided for @stayInGame.
  ///
  /// In ru, this message translates to:
  /// **'Остаюсь в игре'**
  String get stayInGame;

  /// No description provided for @cantCome.
  ///
  /// In ru, this message translates to:
  /// **'Не смогу прийти'**
  String get cantCome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
