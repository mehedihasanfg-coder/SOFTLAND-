import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CSV storage preserves leading-zero mobile IDs and commas in names', () {
    final encoded = const ListToCsvConverter().convert([
      ['Employee ID', 'Employee Name'],
      ['01700111222', 'Rahman, Ahmed'],
    ]);

    final decoded = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(encoded);

    expect(decoded[1][0], '01700111222');
    expect(decoded[1][1], 'Rahman, Ahmed');
  });
}
