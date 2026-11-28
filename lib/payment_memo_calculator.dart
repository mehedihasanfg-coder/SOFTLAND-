class PaymentMemoTotals {
  final double previousPaid;
  final double currentPaid;
  final double totalPaid;
  final double remainingBalance;

  const PaymentMemoTotals({
    required this.previousPaid,
    required this.currentPaid,
    required this.totalPaid,
    required this.remainingBalance,
  });

  static double _read(String? value) =>
      double.tryParse((value ?? '0').replaceAll(',', '').trim()) ?? 0;

  static double currentPaidForRecord(Map<String, String> memo) {
    final currentText = memo['Current Paid'];
    if (currentText != null && currentText.trim().isNotEmpty) {
      return _read(currentText);
    }
    return _read(memo['Total Paid']) - _read(memo['Previous Paid']);
  }

  /// Reads payments for one customer up to (but not including) an edited memo.
  /// The ledger order is the saved memo order; later entries are never counted
  /// as "previous paid" when an earlier memo is edited.
  static double previousPaidFromLedger({
    required List<Map<String, String>> ledger,
    required String customerId,
    String? stopBeforeMemoNumber,
  }) {
    if (customerId.trim().isEmpty) return 0;
    var paid = 0.0;
    for (final memo in ledger) {
      if (stopBeforeMemoNumber != null &&
          stopBeforeMemoNumber.isNotEmpty &&
          (memo['Memo Number'] ?? '').trim() == stopBeforeMemoNumber) {
        break;
      }
      if ((memo['Customer ID'] ?? '').trim() != customerId.trim()) continue;

      paid += currentPaidForRecord(memo);
    }
    return paid;
  }

  static PaymentMemoTotals calculate({
    required double totalPrice,
    required double previousPaid,
    required double currentPaid,
  }) {
    final total = previousPaid + currentPaid;
    return PaymentMemoTotals(
      previousPaid: previousPaid,
      currentPaid: currentPaid,
      totalPaid: total,
      remainingBalance: totalPrice - total,
    );
  }

  static double totalPaidForCustomer({
    required List<Map<String, String>> ledger,
    required String customerId,
  }) =>
      previousPaidFromLedger(ledger: ledger, customerId: customerId);

  /// Rebuilds cumulative balances after an old memo is edited or removed.
  static List<Map<String, String>> recalculateLedger(
    List<Map<String, String>> source,
  ) {
    final runningPaid = <String, double>{};
    return source.map((original) {
      final memo = Map<String, String>.from(original);
      final customerId = (memo['Customer ID'] ?? '').trim();
      if (customerId.isEmpty) return memo;

      final previous = runningPaid[customerId] ?? 0;
      final current = currentPaidForRecord(memo);
      final total = previous + current;
      final balance = _read(memo['Total Price']) - total;

      memo['Previous Paid'] = previous.toStringAsFixed(2);
      memo['Current Paid'] = current.toStringAsFixed(2);
      memo['Total Paid'] = total.toStringAsFixed(2);
      memo['Remaining Balance'] = balance.toStringAsFixed(2);
      runningPaid[customerId] = total;
      return memo;
    }).toList();
  }
}
