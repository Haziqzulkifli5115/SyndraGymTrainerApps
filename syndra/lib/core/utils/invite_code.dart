import 'dart:math';

/// Generates a code like "SYN-4F8K2".
/// Avoids ambiguous chars (0/O, 1/I/L) for easy sharing.
class InviteCode {
  static const _chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String generate() {
    final rand = Random.secure();
    final body = List.generate(5, (_) => _chars[rand.nextInt(_chars.length)])
        .join();
    return 'SYN-$body';
  }
}