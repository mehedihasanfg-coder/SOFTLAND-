import 'package:intl/intl.dart';

class BusinessReporting {
  static DateTime? parseDate(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;

    final iso = DateTime.tryParse(raw);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    const patterns = [
      'dd MMM yyyy',
      'd MMM yyyy',
      'dd/MM/yyyy',
      'd/M/yyyy',
      'yyyy/MM/dd',
      'MMMM yyyy',
      'MMM yyyy',
    ];
    for (final pattern in patterns) {
      try {
        final parsed = DateFormat(pattern, 'en').parseStrict(raw);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        // Try the next supported date representation.
      }
    }
    return null;
  }

  static DateTime? recordDate(Map<String, String> values) {
    for (final field in [
      'Date',
      'Payment Date',
      'Letter Date',
      'Salary Month',
      'Date / Period',
    ]) {
      final parsed = parseDate(values[field]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool isWithinPeriod(
    Map<String, String> values, {
    required DateTime start,
    required DateTime end,
  }) {
    final date = recordDate(values);
    if (date == null) return false;
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    return !date.isBefore(first) && !date.isAfter(last);
  }

  static List<Map<String, String>> filterRecords(
    List<Map<String, String>> records, {
    required DateTime start,
    required DateTime end,
  }) =>
      records.where((record) => isWithinPeriod(
        record,
        start: start,
        end: end,
      )).toList();

  static double sumAmount(
    List<Map<String, String>> records, {
    required String amountField,
    required DateTime start,
    required DateTime end,
  }) {
    final filtered = filterRecords(records, start: start, end: end);
    return filtered.fold<double>(0, (sum, record) {
      final amount = double.tryParse(
        (record[amountField] ?? '0').replaceAll(',', '').trim(),
      ) ?? 0;
      return sum + amount;
    });
  }
}
