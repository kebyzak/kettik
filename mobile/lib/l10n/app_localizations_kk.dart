// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get languageName => 'Қазақша';

  @override
  String get tabGames => 'Ойындар';

  @override
  String get tabCreate => 'Жинау';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get city => 'Астана';

  @override
  String get back => 'Артқа';

  @override
  String get close => 'Жабу';

  @override
  String get backToGame => 'Ойынға оралу';

  @override
  String get you => 'Сіз';

  @override
  String get youShort => 'сіз';

  @override
  String get today => 'Бүгін';

  @override
  String get tomorrow => 'Ертең';

  @override
  String statusFunding(String time) {
    return 'Жинап жатырмыз · $time дейін';
  }

  @override
  String get statusConfirmed => 'Ойын өтеді';

  @override
  String get statusExpired => 'Жиналмадық — ақшаны қайтарамыз';

  @override
  String get statusCancelled => 'Тоқтатылды — ақшаны қайтарамыз';

  @override
  String get rejectPlaceTaken =>
      'Бұл орынды жаңа ғана біреу алды. Сізден ақша алынған жоқ.';

  @override
  String get rejectAlreadyInGame => 'Бұл ойында сізде орын бар.';

  @override
  String get rejectFundingClosed => 'Бұл ойынға жинау жабылды.';

  @override
  String get rejectHoldExpired =>
      'Төлем уақыты өтті. Ақша алынып қалса, автоматты түрде қайтарылады.';

  @override
  String get rejectNotHeld => 'Алдымен орын алыңыз.';

  @override
  String get rejectCannotLeave => 'Енді ақшаны қайтарып шығу мүмкін емес.';

  @override
  String get rejectSlotTaken => 'Бұл уақыт бос емес. Басқасын таңдаңыз.';

  @override
  String get rejectTooLate => 'Бұл уақытқа ойын жинауға үлгермейміз.';

  @override
  String get offline => 'Сервермен байланыс жоқ. Интернетті тексеріңіз.';

  @override
  String get tryAgain => 'Болмады. Қайталап көріңіз.';

  @override
  String get tryAgainShort => 'Қайталау';

  @override
  String get authTooMany => 'Сұраулар тым көп. Бір сағаттан кейін көріңіз.';

  @override
  String refundPromise(String time, String amount) {
    return '$time дейін жиналмасақ, $amount толық қайтарамыз.';
  }

  @override
  String refundAfterConfirm(String time) {
    return 'Ойын расталғаннан кейін ақшаны орныңызды $time дейін біреу алса ғана қайтарамыз.';
  }

  @override
  String get authBadEmail => 'Поштаны тексеріңіз: мекенжайда қате бар сияқты.';

  @override
  String authWrongCode(int count) {
    return 'Код қате. Қалған әрекет: $count.';
  }

  @override
  String get authCodeBurned => 'Код енді жарамсыз. Жаңасын сұраңыз.';

  @override
  String get authCodeExpired => 'Кодтың мерзімі өтті. Жаңасын сұраңыз.';

  @override
  String get authBadName => 'Аты 2–40 таңбадан тұруы керек.';

  @override
  String get codeTitle => 'Хаттағы код';

  @override
  String codeLead(String email, int minutes) {
    return '$email мекенжайына жібердік. Код $minutes минут жарамды.';
  }

  @override
  String codeResendIn(String time) {
    return 'Жаңа код $time кейін';
  }

  @override
  String get codeResend => 'Жаңа код жіберу';

  @override
  String get codeNoEmail =>
      'Хат келмеді ме? «Спам» және «Промоакциялар» қалталарын тексеріңіз.';

  @override
  String get emailTitle => 'Поштамен кіру';

  @override
  String get emailLead =>
      'Поштаңызға код жібереміз. Аккаунт әлі жоқ болса, ашып береміз — тек атыңыз керек.';

  @override
  String get emailGetCode => 'Код алу';

  @override
  String get nameTitle => 'Атыңыз кім?';

  @override
  String get nameLead =>
      'Атыңызды құрамдағы ойыншылар мен ойынды жинаушы көреді.';

  @override
  String get nameHint => 'Аты-жөні';

  @override
  String get nameDone => 'Дайын';

  @override
  String confirmedSquad(int paid, int size) {
    return '$paid/$size · құрам жиналды';
  }

  @override
  String confirmedLead(String venue, String time) {
    return '$venue алаңы сіздерге брондалды. Алаңда $time-да күтеміз.';
  }

  @override
  String get openTicket => 'Билетті ашу';

  @override
  String bannerHolding(int number, String time) {
    return '№$number орынды тағы $time ұстап тұрмыз';
  }

  @override
  String get pay => 'Төлеу';

  @override
  String paidOf(int paid, int size) {
    return '$size орынның $paid төленді';
  }

  @override
  String get feedSeeksReplacement => 'ауыстырушы іздеуде';

  @override
  String get feedPlacesHeld => 'орындар ұсталып тұр';

  @override
  String placesLeft(int count) {
    return '$count орын';
  }

  @override
  String get emptyTitle => 'Алаң бос';

  @override
  String get emptyLead =>
      'Әзірге ешкім жинап жатқан жоқ. Өзіңіз жинаңыз — бірінші орын сіздікі.';

  @override
  String get createGame => 'Ойын жинау';

  @override
  String get takeFailedTitle => 'Орын алу мүмкін болмады';

  @override
  String get pickAnother => 'Басқа орын таңдау';

  @override
  String get cancelGameQuestion => 'Ойынды тоқтатасыз ба?';

  @override
  String get leaveGameQuestion => 'Ойыннан шығасыз ба?';

  @override
  String get cancelGameBody => 'Уақыт босайды, барлық төлем толық қайтарылады.';

  @override
  String leaveGameBody(String amount, int number) {
    return '$amount толық қайтарамыз. №$number орынды басқа біреу алады.';
  }

  @override
  String get cancelGame => 'Ойынды тоқтату';

  @override
  String get leave => 'Шығу';

  @override
  String get stay => 'Қалу';

  @override
  String get paidCaption => 'төледі';

  @override
  String get lineup => 'Құрам';

  @override
  String payPlace(int number, String amount) {
    return '№$number орынға төлеу · $amount';
  }

  @override
  String inSquad(int number) {
    return 'Сіз құрамдасыз · №$number';
  }

  @override
  String get leaveWithRefund => 'Шығып, ақшаны қайтару';

  @override
  String takePlace(int number, String amount) {
    return '№$number орынды алу · $amount';
  }

  @override
  String get allHeld => 'Барлық орын ұсталып тұр';

  @override
  String get take => 'алу';

  @override
  String get seekingReplacement => 'ауыстырушы іздеудеміз';

  @override
  String insteadOf(String name) {
    return '$name орнына';
  }

  @override
  String get organizer => 'жинаушы';

  @override
  String placeYours(int number) {
    return '№$number орын сіздікі';
  }

  @override
  String get placeFreed => 'Орын босады';

  @override
  String get factGame => 'Ойын';

  @override
  String get factWhen => 'Қашан';

  @override
  String get factRent => 'Жалға алу';

  @override
  String rentFor(String amount, int size) {
    return '$amount, $size орын';
  }

  @override
  String get yourShare => 'Сіздің үлесіңіз';

  @override
  String get alreadyFull => 'Ойын жиналып қойған — төлеңіз, орын сіздікі.';

  @override
  String get changeMind => 'Растауға дейін ойыңыз өзгерсе, ақша қайтарылады.';

  @override
  String payAmount(String amount) {
    return '$amount төлеу';
  }

  @override
  String get payByCard => 'Банктің қорғалған бетінде картамен';

  @override
  String get releasePlace => 'Орынды босату';

  @override
  String get holdingWhilePay => 'Төлеп жатқанда орынды ұстап тұрмыз';

  @override
  String get timeLeft => 'Қалды';

  @override
  String get timeUp => 'Уақыт бітті';

  @override
  String get timeUpBody => 'Ақша алынып үлгерсе, автоматты түрде қайтарылады.';

  @override
  String get duration60 => '1 сағат';

  @override
  String get duration90 => '1,5 сағат';

  @override
  String get duration120 => '2 сағат';

  @override
  String get levelCasual => 'Әуесқойлар';

  @override
  String get levelMiddle => 'Орташа';

  @override
  String get levelStrong => 'Мықты';

  @override
  String formatThreeTeams(int side) {
    return '$side×$side, үш команда';
  }

  @override
  String formatWithSub(int side) {
    return '$side×$side, бір ауыстырумен';
  }

  @override
  String pitchOne(String venue) {
    return '$venue · 1-алаң';
  }

  @override
  String artificialTurf(String address) {
    return '$address · жасанды шөп';
  }

  @override
  String startOn(String date) {
    return '$date · басталуы';
  }

  @override
  String get players => 'Ойыншылар';

  @override
  String firstPlaceYours(String format) {
    return '$format · бірінші орын сіздікі';
  }

  @override
  String get fewerPlayers => 'Ойыншыны азайту';

  @override
  String get morePlayers => 'Ойыншыны көбейту';

  @override
  String rentSplit(String amount, int size) {
    return 'Жалға алу $amount : $size';
  }

  @override
  String fromAmount(String amount) {
    return '$amount бастап';
  }

  @override
  String get perPlayer => ' ойыншыдан';

  @override
  String get level => 'Деңгей';

  @override
  String fundingClosesAt(String time) {
    return 'Жинау $time-да жабылады. Жиналмасақ, барлығына ақша қайтарылады.';
  }

  @override
  String get noSlotsToday => 'Бұл күні бос уақыт жоқ';

  @override
  String get noVenues => 'Әзірге алаңдар жоқ. Жақында пайда болады';

  @override
  String createAndPay(String amount) {
    return 'Құру және төлеу · $amount';
  }

  @override
  String slotTaken(String time) {
    return '$time, бос емес';
  }

  @override
  String get myGames => 'Менің ойындарым';

  @override
  String get upcoming => 'Жақында';

  @override
  String get past => 'Өткен';

  @override
  String get myGamesEmpty => 'Мұнда сізде орын бар ойындар шығады.';

  @override
  String get account => 'Аккаунт';

  @override
  String get language => 'Тіл';

  @override
  String get notifications => 'Хабарландырулар';

  @override
  String get notificationsOn => 'Қосулы';

  @override
  String get signOut => 'Шығу';

  @override
  String played(int count) {
    return 'Ойналды · $count ойыншы';
  }

  @override
  String collectingUntil(int paid, int size, String time) {
    return '$paid/$size · $time дейін жинау';
  }

  @override
  String placeNumber(int number) {
    return '№$number орын';
  }

  @override
  String get signedOutLead =>
      'Орын алу, ойын жинау және оларды осында көру үшін кіріңіз. Ойындарды кірмей-ақ көруге болады.';

  @override
  String get signInEmail => 'Поштамен кіру';

  @override
  String get gameRunning => 'Ойын жүріп жатыр';

  @override
  String startsIn(String day, int hours, int minutes) {
    return '$day · $hours сағ $minutes мин кейін';
  }

  @override
  String untilTime(String address, String time) {
    return '$address · $time дейін';
  }

  @override
  String get cellNumber => 'Нөмір';

  @override
  String get cellFormat => 'Формат';

  @override
  String get cellPaid => 'Төленді';

  @override
  String lineupCount(int count) {
    return 'Құрам · $count';
  }

  @override
  String replaceSearch(String time, String amount) {
    return '$time дейін орныңызға адам іздейміз. Біреу алса, $amount қайтарамыз. Алмаса, ақша орын үшін қалады.';
  }

  @override
  String get stayInGame => 'Ойында қаламын';

  @override
  String get cantCome => 'Келе алмаймын';
}
