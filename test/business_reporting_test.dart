import 'package:flutter_test/flutter_test.dart';
import 'package:softland_business_manager/business_reporting.dart';

void main() {
  final start = DateTime(2026, 11, 1);
  final end = DateTime(2026, 11, 30);

  test('parses ISO, day-month and month-year date formats', () {
    expect(BusinessReporting.parseDate('2026-11-28'), DateTime(2026, 11, 28));
    expect(BusinessReporting.parseDate('28 Nov 2026'), DateTime(2026, 11, 28));
    expect(BusinessReporting.parseDate('November 2026'), DateTime(2026, 11, 1));
  });

  test('period filtering includes both boundary dates', () {
    final records = [
      {'Date': '2026-10-31', 'Amount': '10'},
      {'Date': '2026-11-01', 'Amount': '20'},
      {'Date': '28 Nov 2026', 'Amount': '30'},
      {'Date': '2026-12-01', 'Amount': '40'},
    ];

    final filtered = BusinessReporting.filterRecords(
      records,
      start: start,
      end: end,
    );

    expect(filtered.length, 2);
  });

  test('period sum parses comma-separated amounts and ignores out-of-period records', () {
    final records = [
      {'Payment Date': '2026-11-02', 'Current Paid': '12,500'},
      {'Payment Date': '2026-10-30', 'Current Paid': '8,000'},
      {'Payment Date': '2026-11-29', 'Current Paid': '500'},
    ];

    expect(
      BusinessReporting.sumAmount(
        records,
        amountField: 'Current Paid',
        start: start,
        end: end,
      ),
      13000,
    );
  });
}
