class PayrollTotals {
  final double totalAmount;
  final double netPayable;

  const PayrollTotals({
    required this.totalAmount,
    required this.netPayable,
  });

  factory PayrollTotals.fromValues(Map<String, String> values) {
    double read(String key) => double.tryParse(
      (values[key] ?? '0').replaceAll(',', '').trim(),
    ) ?? 0;

    final total = [
      'Basic Salary',
      'House Rent',
      'Medical',
      'Conveyance',
      'Special Allowance',
      'Eid-ul-Fitr Bonus',
      'Eid-ul-Azha Bonus',
      'Yearly Bonus',
      'Overtime Amount (Manual Entry)',
    ].fold<double>(0, (sum, key) => sum + read(key));

    return PayrollTotals(
      totalAmount: total,
      netPayable: total - read('Advance') - read('Deduction'),
    );
  }
}
