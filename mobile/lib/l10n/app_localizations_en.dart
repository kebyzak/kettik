// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get tabGames => 'Games';

  @override
  String get tabCreate => 'Host';

  @override
  String get tabProfile => 'Profile';

  @override
  String get city => 'Astana';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get backToGame => 'Back to the game';

  @override
  String get you => 'You';

  @override
  String get youShort => 'you';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String statusFunding(String time) {
    return 'Collecting · until $time';
  }

  @override
  String get statusConfirmed => 'Game is on';

  @override
  String get statusExpired => 'Not enough players — refunding';

  @override
  String get statusCancelled => 'Cancelled — refunding';

  @override
  String get rejectPlaceTaken =>
      'Someone just took this place. You haven\'t been charged.';

  @override
  String get rejectAlreadyInGame => 'You already have a place in this game.';

  @override
  String get rejectFundingClosed =>
      'This game is no longer collecting players.';

  @override
  String get rejectHoldExpired =>
      'Time to pay ran out. If you were charged, the money comes back automatically.';

  @override
  String get rejectNotHeld => 'Take a place first.';

  @override
  String get rejectCannotLeave => 'You can no longer leave with a refund.';

  @override
  String get rejectSlotTaken => 'That time is taken. Pick another.';

  @override
  String get rejectTooLate => 'Too late to fill a game at that time.';

  @override
  String get offline => 'Can\'t reach the server. Check your connection.';

  @override
  String get tryAgain => 'Something went wrong. Try again.';

  @override
  String get tryAgainShort => 'Retry';

  @override
  String get authTooMany => 'Too many requests. Try again in an hour.';

  @override
  String refundPromise(String time, String amount) {
    return 'If we\'re not full by $time, you get $amount back in full.';
  }

  @override
  String refundAfterConfirm(String time) {
    return 'After confirmation we refund only if someone takes your place by $time.';
  }

  @override
  String get authBadEmail => 'Check your email: the address looks mistyped.';

  @override
  String authWrongCode(int count) {
    return 'Wrong code. Attempts left: $count.';
  }

  @override
  String get authCodeBurned => 'This code no longer works. Request a new one.';

  @override
  String get authCodeExpired => 'The code has expired. Request a new one.';

  @override
  String get authBadName => 'Name must be 2 to 40 characters.';

  @override
  String get codeTitle => 'Code from the email';

  @override
  String codeLead(String email, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return 'Sent to $email. The code is valid for $_temp0.';
  }

  @override
  String codeResendIn(String time) {
    return 'New code in $time';
  }

  @override
  String get codeResend => 'Send a new code';

  @override
  String get codeNoEmail => 'No email? Check Spam and Promotions.';

  @override
  String get emailTitle => 'Sign in with email';

  @override
  String get emailLead =>
      'We\'ll email you a code. No account yet? We\'ll create one — all we need is your name.';

  @override
  String get emailGetCode => 'Get code';

  @override
  String get nameTitle => 'What\'s your name?';

  @override
  String get nameLead => 'Players in the lineup and the organizer will see it.';

  @override
  String get nameHint => 'First and last name';

  @override
  String get nameDone => 'Done';

  @override
  String confirmedSquad(int paid, int size) {
    return '$paid/$size · lineup complete';
  }

  @override
  String confirmedLead(String venue, String time) {
    return '$venue is booked for you. See you on the pitch at $time.';
  }

  @override
  String get openTicket => 'Open ticket';

  @override
  String bannerHolding(int number, String time) {
    return 'Holding place #$number for $time';
  }

  @override
  String get pay => 'Pay';

  @override
  String paidOf(int paid, int size) {
    return '$paid of $size paid';
  }

  @override
  String get feedSeeksReplacement => 'looking for a sub';

  @override
  String get feedPlacesHeld => 'places on hold';

  @override
  String placesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '$count place',
    );
    return '$_temp0';
  }

  @override
  String get emptyTitle => 'The pitch is empty';

  @override
  String get emptyLead =>
      'Nobody\'s hosting yet. Host a game — the first place is yours.';

  @override
  String get createGame => 'Host a game';

  @override
  String get takeFailedTitle => 'Couldn\'t take the place';

  @override
  String get pickAnother => 'Pick another place';

  @override
  String get cancelGameQuestion => 'Cancel the game?';

  @override
  String get leaveGameQuestion => 'Leave the game?';

  @override
  String get cancelGameBody =>
      'The slot is released and every payment is refunded in full.';

  @override
  String leaveGameBody(String amount, int number) {
    return 'We\'ll refund $amount in full. Someone else will take place #$number.';
  }

  @override
  String get cancelGame => 'Cancel game';

  @override
  String get leave => 'Leave';

  @override
  String get stay => 'Stay';

  @override
  String get paidCaption => 'paid';

  @override
  String get lineup => 'Lineup';

  @override
  String payPlace(int number, String amount) {
    return 'Pay for place #$number · $amount';
  }

  @override
  String inSquad(int number) {
    return 'You\'re in · #$number';
  }

  @override
  String get leaveWithRefund => 'Leave and get a refund';

  @override
  String takePlace(int number, String amount) {
    return 'Take #$number · $amount';
  }

  @override
  String get allHeld => 'All places are on hold';

  @override
  String get take => 'take';

  @override
  String get seekingReplacement => 'finding a sub';

  @override
  String insteadOf(String name) {
    return 'instead of $name';
  }

  @override
  String get organizer => 'host';

  @override
  String placeYours(int number) {
    return 'Place #$number is yours';
  }

  @override
  String get placeFreed => 'The place was released';

  @override
  String get factGame => 'Game';

  @override
  String get factWhen => 'When';

  @override
  String get factRent => 'Rent';

  @override
  String rentFor(String amount, int size) {
    String _temp0 = intl.Intl.pluralLogic(
      size,
      locale: localeName,
      other: '$size places',
      one: '$size place',
    );
    return '$amount for $_temp0';
  }

  @override
  String get yourShare => 'Your share';

  @override
  String get alreadyFull =>
      'The game is already full — pay and the place is yours.';

  @override
  String get changeMind =>
      'Change your mind before confirmation and you get your money back.';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get payByCard => 'By card on the bank\'s secure page';

  @override
  String get releasePlace => 'Release the place';

  @override
  String get holdingWhilePay => 'Holding it while you pay';

  @override
  String get timeLeft => 'Time left';

  @override
  String get timeUp => 'Time\'s up';

  @override
  String get timeUpBody =>
      'If you were charged, the money comes back automatically.';

  @override
  String get duration60 => '1 hour';

  @override
  String get duration90 => '1.5 hours';

  @override
  String get duration120 => '2 hours';

  @override
  String get levelCasual => 'Casual';

  @override
  String get levelMiddle => 'Intermediate';

  @override
  String get levelStrong => 'Advanced';

  @override
  String formatThreeTeams(int side) {
    return '$side×$side, three teams';
  }

  @override
  String formatWithSub(int side) {
    return '$side×$side plus a sub';
  }

  @override
  String pitchOne(String venue) {
    return '$venue · pitch 1';
  }

  @override
  String artificialTurf(String address) {
    return '$address · artificial turf';
  }

  @override
  String startOn(String date) {
    return '$date · start';
  }

  @override
  String get players => 'Players';

  @override
  String firstPlaceYours(String format) {
    return '$format · the first place is yours';
  }

  @override
  String get fewerPlayers => 'Fewer players';

  @override
  String get morePlayers => 'More players';

  @override
  String rentSplit(String amount, int size) {
    return 'Rent $amount ÷ $size';
  }

  @override
  String fromAmount(String amount) {
    return 'from $amount';
  }

  @override
  String get perPlayer => ' per player';

  @override
  String get level => 'Level';

  @override
  String fundingClosesAt(String time) {
    return 'Collecting closes at $time. If we don\'t fill up, everyone gets their money back.';
  }

  @override
  String get noSlotsToday => 'No free time left today';

  @override
  String createAndPay(String amount) {
    return 'Create and pay · $amount';
  }

  @override
  String slotTaken(String time) {
    return '$time, taken';
  }

  @override
  String get myGames => 'My games';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get myGamesEmpty => 'Games where you have a place will show up here.';

  @override
  String get account => 'Account';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsOn => 'On';

  @override
  String get signOut => 'Sign out';

  @override
  String played(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '$count player',
    );
    return 'Played · $_temp0';
  }

  @override
  String collectingUntil(int paid, int size, String time) {
    return '$paid/$size · collecting until $time';
  }

  @override
  String placeNumber(int number) {
    return 'place #$number';
  }

  @override
  String get signedOutLead =>
      'Sign in to take places, host games and see them here. You can browse games without signing in.';

  @override
  String get signInEmail => 'Sign in with email';

  @override
  String get gameRunning => 'Game in progress';

  @override
  String startsIn(String day, int hours, int minutes) {
    return '$day · in $hours h $minutes min';
  }

  @override
  String untilTime(String address, String time) {
    return '$address · until $time';
  }

  @override
  String get cellNumber => 'Number';

  @override
  String get cellFormat => 'Format';

  @override
  String get cellPaid => 'Paid';

  @override
  String lineupCount(int count) {
    return 'Lineup · $count';
  }

  @override
  String replaceSearch(String time, String amount) {
    return 'We\'re looking for a sub until $time. If someone takes your place, we refund $amount. If not, the payment stays with the place.';
  }

  @override
  String get stayInGame => 'I\'m staying';

  @override
  String get cantCome => 'I can\'t make it';
}
