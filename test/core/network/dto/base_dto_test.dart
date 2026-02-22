import 'package:crushhour/core/network/dto/base_dto.dart';
import 'package:flutter_test/flutter_test.dart';

class _DefaultDto extends BaseDto {
  const _DefaultDto();

  @override
  Map<String, dynamic> toJson() => const <String, dynamic>{'kind': 'default'};
}

class _SimpleDto extends BaseDto {
  const _SimpleDto(this.value);

  final String value;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'value': value};

  @override
  String? validate() {
    if (value.isEmpty) {
      return 'value cannot be empty';
    }
    return null;
  }
}

class _SimpleMapper extends DtoMapper<_SimpleDto, String> {
  const _SimpleMapper();

  @override
  String toDomain(_SimpleDto dto) => dto.value;

  @override
  _SimpleDto toDto(String model) => _SimpleDto(model);
}

void main() {
  group('BaseDto', () {
    test('default validate returns null and isValid is true', () {
      const dto = _DefaultDto();
      expect(dto.validate(), isNull);
      expect(dto.isValid, isTrue);
    });

    test('isValid reflects overridden validate result', () {
      const invalid = _SimpleDto('');
      const valid = _SimpleDto('ok');
      expect(invalid.isValid, isFalse);
      expect(valid.isValid, isTrue);
    });
  });

  group('PaginatedDto', () {
    test('toJson serializes fields including optional values', () {
      const dto = PaginatedDto<_SimpleDto>(
        items: <_SimpleDto>[_SimpleDto('a'), _SimpleDto('b')],
        page: 2,
        pageSize: 10,
        hasMore: true,
        totalCount: 42,
        nextCursor: 'cursor-1',
      );

      final json = dto.toJson();

      expect(json['items'], hasLength(2));
      expect(json['page'], 2);
      expect(json['page_size'], 10);
      expect(json['has_more'], isTrue);
      expect(json['total_count'], 42);
      expect(json['next_cursor'], 'cursor-1');
    });

    test('fromJson uses parser and default pagination values', () {
      final parsed = PaginatedDto.fromJson<_SimpleDto>(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'value': 'x'},
          <String, dynamic>{'value': 'y'},
        ],
      }, (json) => _SimpleDto(json.getString('value') ?? ''));

      expect(parsed.items.map((e) => e.value), <String>['x', 'y']);
      expect(parsed.page, 0);
      expect(parsed.pageSize, 20);
      expect(parsed.hasMore, isFalse);
      expect(parsed.totalCount, isNull);
      expect(parsed.nextCursor, isNull);
    });

    test('fromJson falls back to empty items when items key is absent', () {
      final parsed = PaginatedDto.fromJson<_SimpleDto>(<String, dynamic>{
        'page': 1,
        'page_size': 5,
        'has_more': true,
      }, (json) => _SimpleDto(json.getString('value') ?? ''));

      expect(parsed.items, isEmpty);
      expect(parsed.page, 1);
      expect(parsed.pageSize, 5);
      expect(parsed.hasMore, isTrue);
    });
  });

  group('ApiResponseDto', () {
    test('toJson serializes BaseDto data and optional fields', () {
      final timestamp = DateTime(2026, 1, 1, 12, 0, 0);
      final dto = ApiResponseDto<_SimpleDto>(
        success: true,
        data: const _SimpleDto('payload'),
        error: 'none',
        errorCode: 'X0',
        message: 'ok',
        timestamp: timestamp,
      );

      final json = dto.toJson();

      expect(json['success'], isTrue);
      expect(json['data'], <String, dynamic>{'value': 'payload'});
      expect(json['error'], 'none');
      expect(json['error_code'], 'X0');
      expect(json['message'], 'ok');
      expect(json['timestamp'], timestamp.toIso8601String());
    });

    test('fromJson parses payload with parser and timestamp', () {
      final dto = ApiResponseDto.fromJson<_SimpleDto>(
        <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{'value': 'parsed'},
          'error': 'e',
          'error_code': 'E1',
          'message': 'm',
          'timestamp': '2026-02-21T10:00:00.000Z',
        },
        (json) => _SimpleDto((json as Map<String, dynamic>)['value'] as String),
      );

      expect(dto.success, isTrue);
      expect(dto.data?.value, 'parsed');
      expect(dto.error, 'e');
      expect(dto.errorCode, 'E1');
      expect(dto.message, 'm');
      expect(dto.timestamp, isNotNull);
    });

    test('fromJson returns null data when parser is absent', () {
      final dto = ApiResponseDto.fromJson<String>(<String, dynamic>{
        'success': true,
        'data': 'raw',
      }, null);

      expect(dto.success, isTrue);
      expect(dto.data, isNull);
    });

    test('success factory sets success fields and timestamp', () {
      final dto = ApiResponseDto<String>.success('ok', message: 'done');
      expect(dto.success, isTrue);
      expect(dto.data, 'ok');
      expect(dto.message, 'done');
      expect(dto.timestamp, isNotNull);
    });

    test('error factory sets failure fields and timestamp', () {
      final dto = ApiResponseDto<String>.error(
        'failed',
        errorCode: 'E42',
        message: 'nope',
      );
      expect(dto.success, isFalse);
      expect(dto.error, 'failed');
      expect(dto.errorCode, 'E42');
      expect(dto.message, 'nope');
      expect(dto.timestamp, isNotNull);
    });
  });

  group('JsonUtils', () {
    test(
      'parseDateTime handles null, DateTime, string, int and invalid input',
      () {
        final now = DateTime(2026, 1, 1);
        expect(JsonUtils.parseDateTime(null), isNull);
        expect(JsonUtils.parseDateTime(now), now);
        expect(
          JsonUtils.parseDateTime('2026-01-01T00:00:00.000Z'),
          isA<DateTime>(),
        );
        expect(JsonUtils.parseDateTime(1), isA<DateTime>());
        expect(JsonUtils.parseDateTime(const <String, dynamic>{}), isNull);
      },
    );

    test('parseInt supports int, double and string', () {
      expect(JsonUtils.parseInt(7), 7);
      expect(JsonUtils.parseInt(7.9), 7);
      expect(JsonUtils.parseInt('9'), 9);
      expect(JsonUtils.parseInt('bad'), isNull);
      expect(JsonUtils.parseInt(true), isNull);
    });

    test('parseDouble supports double, int and string', () {
      expect(JsonUtils.parseDouble(7.5), 7.5);
      expect(JsonUtils.parseDouble(7), 7.0);
      expect(JsonUtils.parseDouble('9.5'), 9.5);
      expect(JsonUtils.parseDouble('bad'), isNull);
      expect(JsonUtils.parseDouble(false), isNull);
    });

    test('parseBool supports bool, int and string variants', () {
      expect(JsonUtils.parseBool(true), isTrue);
      expect(JsonUtils.parseBool(1), isTrue);
      expect(JsonUtils.parseBool(0), isFalse);
      expect(JsonUtils.parseBool('true'), isTrue);
      expect(JsonUtils.parseBool('1'), isTrue);
      expect(JsonUtils.parseBool('false'), isFalse);
      expect(JsonUtils.parseBool('0'), isFalse);
      expect(JsonUtils.parseBool(1.0), isNull);
    });

    test('parseList and parseMap handle valid and invalid inputs', () {
      final list = JsonUtils.parseList<int>(<dynamic>[
        1,
        '2',
        3,
      ], (value) => int.parse(value.toString()));
      expect(list, <int>[1, 2, 3]);
      expect(JsonUtils.parseList<int>('not-a-list', (v) => 0), isNull);

      final map = JsonUtils.parseMap<int>(<String, dynamic>{
        'a': 1,
        'b': '2',
      }, (value) => int.parse(value.toString()));
      expect(map, <String, int>{'a': 1, 'b': 2});
      expect(JsonUtils.parseMap<int>(<dynamic>[1, 2], (value) => 0), isNull);
    });

    test('getNestedValue resolves nested paths and parser branches', () {
      final json = <String, dynamic>{
        'a': <String, dynamic>{
          'b': <String, dynamic>{'c': '5'},
        },
      };

      expect(
        JsonUtils.getNestedValue<String>(json, <String>['a', 'b', 'c']),
        '5',
      );
      expect(
        JsonUtils.getNestedValue<int>(json, <String>[
          'a',
          'b',
          'c',
        ], (value) => int.parse(value.toString())),
        5,
      );
      expect(
        JsonUtils.getNestedValue<String>(json, <String>['a', 'x']),
        isNull,
      );
      expect(
        JsonUtils.getNestedValue<String>(json, <String>['a', 'b', 'c', 'd']),
        isNull,
      );
      expect(
        JsonUtils.getNestedValue<String>(json, <String>['missing']),
        isNull,
      );
    });
  });

  group('SafeJsonAccess extension', () {
    test('returns typed values for all getters', () {
      final json = <String, dynamic>{
        'str': 'hello',
        'int': '42',
        'double': '1.5',
        'bool': 'true',
        'date': '2026-01-01T00:00:00.000Z',
        'list': <dynamic>['1', 2],
        'map': <dynamic, dynamic>{1: 'x'},
        'nested': <String, dynamic>{
          'k': <String, dynamic>{'v': 3},
        },
      };

      expect(json.getString('str'), 'hello');
      expect(json.getInt('int'), 42);
      expect(json.getDouble('double'), 1.5);
      expect(json.getBool('bool'), isTrue);
      expect(json.getDateTime('date'), isA<DateTime>());
      expect(
        json.getList<int>('list', (value) => int.parse(value.toString())),
        <int>[1, 2],
      );
      expect(json.getMap('map'), <String, dynamic>{'1': 'x'});
      expect(json.getNested<int>(<String>['nested', 'k', 'v']), 3);
    });
  });

  group('Validation utilities', () {
    test(
      'ValidationResult factories and toString cover valid/invalid states',
      () {
        final valid = ValidationResult.valid();
        expect(valid.isValid, isTrue);
        expect(valid.firstError, isNull);
        expect(valid.toString(), 'ValidationResult: Valid');

        final invalid = ValidationResult.invalid(const <ValidationError>[
          ValidationError(field: 'email', message: 'invalid'),
        ]);
        expect(invalid.isValid, isFalse);
        expect(invalid.firstError, 'invalid');
        expect(invalid.toString(), contains('ValidationResult: Invalid'));

        final single = ValidationResult.single('name', 'required');
        expect(single.isValid, isFalse);
        expect(single.errors, hasLength(1));
        expect(single.firstError, 'required');
      },
    );

    test('ValidationError toString outputs field and message', () {
      const error = ValidationError(field: 'phone', message: 'bad');
      expect(error.toString(), 'phone: bad');
    });

    test('DtoValidator enforces all validation helpers and build states', () {
      final validator = DtoValidator()
          .require(false, 'f1', 'bad-1')
          .requireNotNull(null, 'f2')
          .requireNotEmpty('', 'f3')
          .requireMinLength('ab', 3, 'f4')
          .requireRange(11, 1, 10, 'f5')
          .requireEmail('bad-email', 'f6');

      final invalid = validator.build();
      expect(invalid.isValid, isFalse);
      expect(invalid.errors.length, 6);
      expect(validator.firstError, isNotNull);

      final valid = DtoValidator()
          .require(true, 'ok', 'ignored')
          .requireNotNull('x', 'ok')
          .requireNotEmpty('x', 'ok')
          .requireMinLength(null, 3, 'ok')
          .requireMinLength('abcd', 3, 'ok')
          .requireRange(5, 1, 10, 'ok')
          .requireEmail('valid@example.com', 'ok')
          .build();
      expect(valid.isValid, isTrue);
      expect(valid.errors, isEmpty);
    });
  });

  group('DtoMapper and debugDto', () {
    test('toDomainList and toDtoList map values correctly', () {
      const mapper = _SimpleMapper();
      final dtos = <_SimpleDto>[const _SimpleDto('a'), const _SimpleDto('b')];
      final domains = mapper.toDomainList(dtos);
      expect(domains, <String>['a', 'b']);

      final dtoList = mapper.toDtoList(<String>['x', 'y']);
      expect(dtoList.map((e) => e.value), <String>['x', 'y']);
    });

    test('debugDto can be called safely', () {
      expect(
        () => debugDto('dto-test', const _SimpleDto('v')),
        returnsNormally,
      );
    });
  });
}
