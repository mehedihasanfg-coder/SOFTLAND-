import 'package:flutter_test/flutter_test.dart';
import 'package:softland_business_manager/payment_memo_calculator.dart';

void main() {
  test('previous paid sums only earlier payments for the selected customer', () {
    final ledger = [
      {'Memo Number': 'CPM-202611-0001', 'Customer ID': '01711111111', 'Current Paid': '10,000', 'Total Paid': '10000', 'Previous Paid': '0'},
      {'Memo Number': 'CPM-202611-0002', 'Customer ID': '01722222222', 'Current Paid': '5,000', 'Total Paid': '5000', 'Previous Paid': '0'},
      {'Memo Number': 'CPM-202611-0003', 'Customer ID': '01711111111', 'Current Paid': '2,500', 'Total Paid': '12500', 'Previous Paid': '10000'},
    ];

    expect(
      PaymentMemoTotals.previousPaidFromLedger(
        ledger: ledger,
        customerId: '01711111111',
      ),
      12500,
    );
  });

  test('editing a memo excludes that memo and all later entries', () {
    final ledger = [
      {'Memo Number': 'M-1', 'Customer ID': 'C1', 'Current Paid': '100'},
      {'Memo Number': 'M-2', 'Customer ID': 'C1', 'Current Paid': '50'},
      {'Memo Number': 'M-3', 'Customer ID': 'C1', 'Current Paid': '25'},
    ];

    expect(
      PaymentMemoTotals.previousPaidFromLedger(
        ledger: ledger,
        customerId: 'C1',
        stopBeforeMemoNumber: 'M-2',
      ),
      100,
    );
  });

  test('memo totals calculate total paid and remaining balance', () {
    final totals = PaymentMemoTotals.calculate(
      totalPrice: 500000,
      previousPaid: 125000,
      currentPaid: 25000,
    );

    expect(totals.totalPaid, 150000);
    expect(totals.remainingBalance, 350000);
  });

  test('recalculating an edited ledger updates later cumulative balances', () {
    final result = PaymentMemoTotals.recalculateLedger([
      {'Memo Number': 'M-1', 'Customer ID': 'C1', 'Total Price': '500', 'Current Paid': '100'},
      {'Memo Number': 'M-2', 'Customer ID': 'C1', 'Total Price': '500', 'Current Paid': '50'},
    ]);

    expect(result[0]['Previous Paid'], '0.00');
    expect(result[0]['Total Paid'], '100.00');
    expect(result[1]['Previous Paid'], '100.00');
    expect(result[1]['Total Paid'], '150.00');
    expect(result[1]['Remaining Balance'], '350.00');
  });
}
