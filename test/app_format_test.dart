import 'package:flutter_test/flutter_test.dart';
import 'package:wordprogressor/shared/utils/app_format.dart';

void main() {
  group('AppFormat.wordCountCompact', () {
    test('below 1000 returns plain number', () {
      expect(AppFormat.wordCountCompact(500), '500');
    });

    test('1500 → "1.5 Tsd."', () {
      expect(AppFormat.wordCountCompact(1500), '1.5 Tsd.');
    });

    test('1000000 → "1.0 Mio."', () {
      expect(AppFormat.wordCountCompact(1000000), '1.0 Mio.');
    });
  });

  group('AppFormat.duration', () {
    test('45 minutes → "45 Min."', () {
      expect(AppFormat.duration(45), '45 Min.');
    });

    test('60 minutes → "1 Std."', () {
      expect(AppFormat.duration(60), '1 Std.');
    });

    test('90 minutes → "1 Std. 30 Min."', () {
      expect(AppFormat.duration(90), '1 Std. 30 Min.');
    });
  });

  group('AppFormat.relativeDate', () {
    test('today returns "heute"', () {
      expect(AppFormat.relativeDate(DateTime.now()), 'heute');
    });

    test('tomorrow returns "morgen"', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(AppFormat.relativeDate(tomorrow), 'morgen');
    });

    test('yesterday returns "gestern"', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppFormat.relativeDate(yesterday), 'gestern');
    });

    test('5 days ahead returns "in 5 Tagen"', () {
      final future = DateTime.now().add(const Duration(days: 5));
      expect(AppFormat.relativeDate(future), 'in 5 Tagen');
    });
  });
}
