import 'package:crushhour/core/security/input_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputSanitizer hotspot branches', () {
    test('sanitizeText handles null, control chars, trim and max length', () {
      expect(InputSanitizer.sanitizeText(null), '');
      expect(InputSanitizer.sanitizeText(''), '');
      expect(
        InputSanitizer.sanitizeText('  hello\x00\x07 world  '),
        'hello world',
      );
      expect(InputSanitizer.sanitizeText('abcdef', maxLength: 3), 'abc');
    });

    test('sanitizeName strips HTML and disallowed characters', () {
      final value = InputSanitizer.sanitizeName("<b>Jöhn</b> O'Neil!@#");
      expect(value, "Jöhn O'Neil");
    });

    test('sanitizeBio strips tags and escapes entities', () {
      final value = InputSanitizer.sanitizeBio('<script>alert("x")</script>&');
      expect(value, 'alert(&quot;x&quot;)&amp;');
    });

    test('sanitizeMessage strips tags including a trailing unterminated tag', () {
      expect(InputSanitizer.sanitizeMessage('<b>hi</b> there'), 'hi there');
      // The naive /<[^>]*>/ stripper leaves this unterminated tag intact.
      expect(
        InputSanitizer.sanitizeMessage('hello<img src=x onerror=alert(1)'),
        'hello',
      );
      // Benign "<" that is not a tag start is preserved.
      expect(
        InputSanitizer.sanitizeMessage('3 < 5 and i <3 you'),
        '3 < 5 and i <3 you',
      );
    });

    test('sanitizeCity and sanitizeJobField keep expected characters', () {
      expect(
        InputSanitizer.sanitizeCity('<i>São-Paulo, BR!</i>'),
        'São-Paulo, BR',
      );
      expect(
        InputSanitizer.sanitizeJobField('<b>R&D (Lead) @ Company!</b>'),
        'R&D (Lead)  Company',
      );
      expect(InputSanitizer.sanitizeJobField('123456', maxLength: 3), '123');
    });

    test('sanitizeInterest and sanitizeInterests trim/filter/take limits', () {
      expect(InputSanitizer.sanitizeInterest('<b>Gaming!!!</b>'), 'Gaming');

      final input = <String>[
        '',
        '  Music ',
        '<i>Art</i>',
        '###',
        for (var i = 0; i < 60; i++) 'item$i',
      ];
      final sanitized = InputSanitizer.sanitizeInterests(input);
      expect(sanitized, isNotEmpty);
      expect(sanitized.first, 'Music');
      expect(sanitized, contains('Art'));
      expect(sanitized.length, 50);
    });

    test('sanitizeUrl validates schemes, authorities and local paths', () {
      expect(InputSanitizer.sanitizeUrl(null), isNull);
      expect(
        InputSanitizer.sanitizeUrl('https://example.com/a.jpg'),
        'https://example.com/a.jpg',
      );
      expect(
        InputSanitizer.sanitizeUrl('http://example.com'),
        'http://example.com',
      );

      expect(
        InputSanitizer.sanitizeUrl('/local/path.jpg', allowLocalPaths: false),
        isNull,
      );
      expect(
        InputSanitizer.sanitizeUrl('/local/path.jpg', allowLocalPaths: true),
        '/local/path.jpg',
      );
      expect(
        InputSanitizer.sanitizeUrl(
          'file:///tmp/image.jpg',
          allowLocalPaths: true,
        ),
        'file:///tmp/image.jpg',
      );

      expect(InputSanitizer.sanitizeUrl('ftp://example.com/a.jpg'), isNull);
      expect(InputSanitizer.sanitizeUrl('javascript:alert(1)'), isNull);
      expect(
        InputSanitizer.sanitizeUrl('https://example.com/data:payload'),
        isNull,
      );
      expect(InputSanitizer.sanitizeUrl('not-a-url'), isNull);
      expect(InputSanitizer.sanitizeUrl('https://'), 'https://');
    });

    test('sanitizeUrls filters invalid entries and enforces max list size', () {
      final urls = <String>[
        'https://example.com/1.jpg',
        'http://example.com/2.jpg',
        'javascript:alert(1)',
        '/local/ignored.jpg',
        for (var i = 0; i < 30; i++) 'https://example.com/$i.jpg',
      ];

      final sanitized = InputSanitizer.sanitizeUrls(
        urls,
        allowLocalPaths: false,
      );
      expect(sanitized, isNotEmpty);
      expect(sanitized, isNot(contains('javascript:alert(1)')));
      expect(sanitized, isNot(contains('/local/ignored.jpg')));
      expect(sanitized.length, 20);
    });

    test('sanitizePhone keeps expected symbols and clamps length', () {
      expect(
        InputSanitizer.sanitizePhone(' +1 (555)-123-4567 ext.9 '),
        '+1 (555)-123-4567 9',
      );

      final long = InputSanitizer.sanitizePhone(
        '+123456789012345678901234567890',
      );
      expect(long.length, 20);
    });

    test('sanitizeEmail normalizes valid email and rejects invalid inputs', () {
      expect(
        InputSanitizer.sanitizeEmail('  USER+tag@Example.COM  '),
        'user+tag@example.com',
      );
      expect(InputSanitizer.sanitizeEmail('bad-email'), '');
      expect(InputSanitizer.sanitizeEmail('${'a' * 250}@x.com'), '');
    });

    test('sanitizeUsername keeps lowercase alnum underscore and max 30', () {
      expect(
        InputSanitizer.sanitizeUsername('  User.Name-123__! '),
        'username123__',
      );
      expect(InputSanitizer.sanitizeUsername('${'a' * 40}_suffix').length, 30);
    });

    test('numeric/geographic sanitizers enforce bounds', () {
      expect(InputSanitizer.sanitizeAge(null), isNull);
      expect(InputSanitizer.sanitizeAge(17), isNull);
      expect(InputSanitizer.sanitizeAge(18), 18);
      expect(InputSanitizer.sanitizeAge(120), 120);
      expect(InputSanitizer.sanitizeAge(121), isNull);

      expect(InputSanitizer.sanitizeHeight(null), isNull);
      expect(InputSanitizer.sanitizeHeight(99), isNull);
      expect(InputSanitizer.sanitizeHeight(100), 100);
      expect(InputSanitizer.sanitizeHeight(250), 250);
      expect(InputSanitizer.sanitizeHeight(251), isNull);

      expect(InputSanitizer.sanitizeLatitude(null), isNull);
      expect(InputSanitizer.sanitizeLatitude(-90), -90);
      expect(InputSanitizer.sanitizeLatitude(90), 90);
      expect(InputSanitizer.sanitizeLatitude(-91), isNull);
      expect(InputSanitizer.sanitizeLatitude(91), isNull);

      expect(InputSanitizer.sanitizeLongitude(null), isNull);
      expect(InputSanitizer.sanitizeLongitude(-180), -180);
      expect(InputSanitizer.sanitizeLongitude(180), 180);
      expect(InputSanitizer.sanitizeLongitude(-181), isNull);
      expect(InputSanitizer.sanitizeLongitude(181), isNull);
    });
  });
}
