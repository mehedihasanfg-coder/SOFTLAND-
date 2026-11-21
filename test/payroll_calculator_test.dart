import 'package:flutter_test/flutter_test.dart';
import 'package:softland_business_manager/payroll_calculator.dart';

void main() {
  test('attendance never reduces basic salary', () {
    final result = PayrollTotals.fromValues({
      'Basic Salary': '20000',
      'Present Days': '5',
      'Absent Days': '25',
      'Total Working Days': '30',
    });

    expect(result.totalAmount, 20000);
    expect(result.netPayable, 20000);
  });

  test('manual overtime and all salary components are included', () {
    final result = PayrollTotals.fromValues({
      'Basic Salary': '20000',
      'House Rent': '5000',
      'Medical': '1000',
      'Conveyance': '500',
      'Special Allowance': '500',
      'Eid-ul-Fitr Bonus': '0',
      'Eid-ul-Azha Bonus': '0',
      'Yearly Bonus': '0',
      'Overtime Amount (Manual Entry)': '1500',
      'Advance': '2000',
      'Deduction': '500',
      'Overtime Hours': '12',
    });

    expect(result.totalAmount, 28500);
    expect(result.netPayable, 26000);
  });

  test('comma-separated money values are parsed', () {
    final result = PayrollTotals.fromValues({
      'Basic Salary': '20,000',
      'Advance': '1,500',
      'Deduction': '500',
    });

    expect(result.totalAmount, 20000);
    expect(result.netPayable, 18000);
  });
}
