import 'package:test/test.dart';
import 'package:utopia_framework/utopia_validators.dart';

void main() {
  final intList = AllowList<int>([1, 2, 3]);
  final floatingList = AllowList<double>([1.0, 2.0, 3.0]);
  final stringList = AllowList<String>(['a', 'b', 'c']);
  final nullableIntList = AllowList<int?>([1, 2, null]);

  String stringReturningFunction<T>(List<T> myList) =>
      'Value must of one of (${myList.join(", ")})';

  group(
    'allow_list_test',
    () {
      test(
        'list getter should return list value',
        () {
          expect(intList.list, [1, 2, 3]);
          expect(floatingList.list, [1.0, 2.0, 3.0]);
          expect(stringList.list, ['a', 'b', 'c']);
          expect(nullableIntList.list, [1, 2, null]);
        },
      );
      test(
        'getDescription: should return proper description',
        () {
          expect(
            intList.getDescription(),
            stringReturningFunction<int>([1, 2, 3]),
          );
          expect(
            floatingList.getDescription(),
            stringReturningFunction<double>([1.0, 2.0, 3.0]),
          );
          expect(
            stringList.getDescription(),
            stringReturningFunction<String>(['a', 'b', 'c']),
          );
          expect(
            nullableIntList.getDescription(),
            stringReturningFunction<int?>([1, 2, null]),
          );
        },
      );

      test(
        'getType(): should return proper data type',
        () {
          expect(intList.getType(), 'int');
          expect(floatingList.getType(), 'double');
          expect(stringList.getType(), 'String');
          expect(nullableIntList.getType(), 'int?');
        },
      );
      test(
        'isArray(): should return false',
        () {
          expect(intList.isArray(), false);
          expect(floatingList.isArray(), false);
          expect(stringList.isArray(), false);
          expect(nullableIntList.isArray(), false);
        },
      );

      test(
        'isValid(): should return proper boolean value',
        () {
          expect(intList.isValid(1), true);
          expect(intList.isValid(5), false);
          expect(intList.isValid('a'), false);
          expect(intList.isValid(const []), false);

          expect(floatingList.isValid(1.0), true);
          expect(floatingList.isValid(5.0), false);
          expect(floatingList.isValid('5'), false);
          expect(floatingList.isValid(const []), false);

          expect(stringList.isValid('a'), true);
          expect(stringList.isValid('z'), false);
          expect(stringList.isValid(10), false);
          expect(stringList.isValid(const []), false);

          expect(nullableIntList.isValid(1), true);
          expect(nullableIntList.isValid(null), true);
          expect(nullableIntList.isValid(5), false);
          expect(nullableIntList.isValid('a'), false);
          expect(nullableIntList.isValid(const []), false);
        },
      );
    },
  );
}
