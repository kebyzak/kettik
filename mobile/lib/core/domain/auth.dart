const codeLife = Duration(minutes: 10);
const resendAfter = Duration(seconds: 60);
const codeAttempts = 5;

enum AuthRejection { badEmail, wrongCode, codeBurned, codeExpired, badName }

class AuthRejected implements Exception {
  const AuthRejected(this.reason, {this.attemptsLeft = 0});

  final AuthRejection reason;
  final int attemptsLeft;
}

String? parseEmail(String raw) {
  final email = raw.trim().toLowerCase();
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ? email : null;
}

String? parseName(String raw) {
  final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  return name.length >= 2 && name.length <= 40 ? name : null;
}
