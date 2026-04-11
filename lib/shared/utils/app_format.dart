import 'package:intl/intl.dart';

/// Central date/number formatting for consistent German locale output.
abstract class AppFormat {
  static final _dateLong = DateFormat('dd. MMMM yyyy', 'de');
  static final _dateShort = DateFormat('dd. MMM yyyy', 'de');
  static final _dateTime = DateFormat('dd. MMM yyyy, HH:mm', 'de');
  static final _wordCount = NumberFormat('#,###', 'de');

  /// e.g. "15. April 2025"
  static String dateLong(DateTime d) => _dateLong.format(d);

  /// e.g. "15. Apr. 2025"
  static String dateShort(DateTime d) => _dateShort.format(d);

  /// e.g. "15. Apr. 2025, 14:32"
  static String dateTime(DateTime d) => _dateTime.format(d);

  /// e.g. "72.400" or "72.400 Wörter"
  static String wordCount(int n, {bool withUnit = false}) {
    final formatted = _wordCount.format(n);
    return withUnit ? '$formatted Wörter' : formatted;
  }

  /// Compact: "72,4 Tsd." / "1,2 Mio."
  static String wordCountCompact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} Mio.';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} Tsd.';
    return n.toString();
  }

  /// Relative: "in 3 Tagen", "gestern", "vor 5 Tagen"
  static String relativeDate(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(now).inDays;
    if (diff == 0) return 'heute';
    if (diff == 1) return 'morgen';
    if (diff == -1) return 'gestern';
    if (diff > 0) return 'in $diff Tagen';
    return 'vor ${diff.abs()} Tagen';
  }

  /// Duration in minutes → "1 Std. 20 Min." / "45 Min."
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes Min.';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h Std.' : '$h Std. $m Min.';
  }
}
