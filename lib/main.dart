import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'payroll_calculator.dart';
import 'payment_memo_calculator.dart';
import 'business_reporting.dart';

void main() => runApp(const SoftlandApp());

const menuItems = [
  'Home', 'Employees', 'Customers', 'Customers Paying Memo',
  'Monthly Salary', 'Daily Income Vouchers', 'Daily Expense Vouchers',
  'Letterheads', 'Contact Information', 'Weekly Report', 'Monthly Report',
  'Annual Report'
];

const employeeFields = [
  'Employee Name', 'Employee ID', 'Designation', 'Department',
  'Phone Number', 'Address', 'Joining Date', 'Basic Salary'
];
const customerFields = [
  'Customer Name', 'Customer ID', 'Phone Number', 'Address',
  'Project / Property', 'Plot / Flat', 'Total Price', 'Notes'
];
const salaryFields = [
  'Employee Name', 'Employee ID', 'Designation', 'Department',
  'Phone Number', 'Employee Address', 'Salary Month', 'Payment Date',
  'Basic Salary', 'Total Working Days', 'Present Days', 'Absent Days',
  'Overtime Hours', 'House Rent', 'Medical', 'Conveyance',
  'Special Allowance', 'Eid-ul-Fitr Bonus', 'Eid-ul-Azha Bonus',
  'Yearly Bonus', 'Overtime Amount (Manual Entry)', 'Total Amount',
  'Advance', 'Deduction', 'Net Payable', 'Payment Reference',
  'Employee Signature', 'Authorized Signature', 'Company Stamp'
];
const paymentFields = [
  'Memo Number', 'Payment Date', 'Customer Name', 'Customer ID',
  'Project / Property', 'Plot / Flat', 'Total Price', 'Previous Paid',
  'Current Paid', 'Total Paid', 'Remaining Balance', 'Payment Method',
  'Customer Signature', 'Authorized Signature', 'Company Stamp', 'Received By', 'Remarks'
];
const incomeFields = [
  'Voucher Number', 'Date', 'Income Category', 'Received From',
  'Description', 'Amount', 'Payment Method', 'Received By'
];
const expenseFields = [
  'Voucher Number', 'Date', 'Expense Category', 'Paid To',
  'Description', 'Amount', 'Payment Method', 'Authorized By'
];
const letterFields = [
  'Letter Date', 'Recipient Name', 'Recipient Address',
  'Subject', 'Letter Body', 'Authorized Signatory'
];
const contactFields = [
  'Company Name', 'Contact Person', 'Phone Number', 'Alternate Phone',
  'Email', 'Office Address', 'Website'
];

List<String> fieldsFor(String section) {
  switch (section) {
    case 'Employees': return employeeFields;
    case 'Customers': return customerFields;
    case 'Monthly Salary': return salaryFields;
    case 'Customers Paying Memo': return paymentFields;
    case 'Daily Income Vouchers': return incomeFields;
    case 'Daily Expense Vouchers': return expenseFields;
    case 'Letterheads': return letterFields;
    case 'Contact Information': return contactFields;
    default: return ['Title / Reference', 'Date / Period', 'Details', 'Amount'];
  }
}

bool isNumericField(String f) {
  final s = f.toLowerCase().trim();
  if (s == 'salary month' || s == 'payment date') return false;
  return s == 'basic salary' || s.contains('amount') || s.contains('bonus') ||
      s.contains('allowance') || s == 'medical' || s == 'conveyance' ||
      s == 'advance' || s == 'deduction' || s.contains('working days') ||
      s.contains('present days') || s.contains('absent days') ||
      s.contains('overtime hours') || s.contains('total price') ||
      s.contains('payment amount') || s == 'previous paid' ||
      s == 'current paid' || s == 'total paid' ||
      s == 'remaining balance';
}

class SoftlandApp extends StatelessWidget {
  const SoftlandApp({super.key});
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102D55);
    const royal = Color(0xFF245DB5);
    return MaterialApp(
      title: 'SOFTLAND Business Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: royal, primary: royal),
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: navy),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class Record {
  final Map<String, String> values;
  Record(Map<String, String> input) : values = Map<String, String>.from(input);
  String get title => values['Employee Name'] ?? values['Customer Name'] ??
      values['Recipient Name'] ?? values['Contact Person'] ??
      values['Title / Reference'] ?? values['Voucher Number'] ??
      values['Memo Number'] ?? values['Employee ID'] ?? 'Untitled record';
  String get date => values['Date'] ?? values['Payment Date'] ??
      values['Salary Month'] ?? values['Letter Date'] ??
      values['Date / Period'] ?? '';
  String get amount => values['Net Payable'] ?? values['Current Paid'] ??
      values['Payment Amount'] ?? values['Amount'] ?? values['Total Amount'] ?? '';
  Map<String, dynamic> toJson() => {'values': values};
  factory Record.fromJson(Map<String, dynamic> j) {
    if (j['values'] is Map) {
      return Record(Map<String, String>.from((j['values'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''))));
    }
    // Read records saved by the first starter version.
    return Record({
      'Title / Reference': j['name']?.toString() ?? '',
      'Date / Period': j['date']?.toString() ?? '',
      'Details': j['details']?.toString() ?? '',
      'Amount': j['amount']?.toString() ?? '',
    });
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String current = 'Home';
  final Map<String, List<Record>> records = {};
  int selected = -1;
  bool loaded = false;
  DateTime? reportFrom;
  DateTime? reportTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('softland_records');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        records[e.key] = (e.value as List).map((x) =>
          Record.fromJson(Map<String, dynamic>.from(x))).toList();
      }
    }
    for (final m in menuItems.skip(1)) { records.putIfAbsent(m, () => []); }
    if (mounted) setState(() => loaded = true);
  }

  Future<void> _save({bool notify = true}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('softland_records', jsonEncode(
      records.map((k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()))));
    if (notify && mounted) _snack('Changes saved on this device.');
  }

  void _snack(String s) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s)));

  Future<void> _editDialog({Record? record}) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => RecordFormDialog(
        section: current,
        initial: record?.values ?? const {},
        employees: records['Employees'] ?? const <Record>[],
        customers: records['Customers'] ?? const <Record>[],
        existingMemos: records['Customers Paying Memo'] ?? const <Record>[],
      ),
    );
    if (result == null) return;
    final identityField = current == 'Employees'
      ? 'Employee ID'
      : current == 'Customers' ? 'Customer ID' : null;
    if (identityField != null) {
      final identity = (result[identityField] ?? '').trim();
      final duplicate = (records[current] ?? []).any((existing) =>
        existing != record &&
        (existing.values[identityField] ?? '').trim() == identity);
      if (identity.isNotEmpty && duplicate) {
        _snack('This mobile number is already registered.');
        return;
      }
    }
    setState(() {
      final list = records[current]!;
      if (record == null) {
        if (current == 'Employees' && list.length >= 10) {
          _snack('Employee limit: 10 profiles.'); return;
        }
        list.add(Record(result));
        selected = list.length - 1;
      } else {
        final i = list.indexOf(record);
        if (i >= 0) { list[i] = Record(result); selected = i; }
      }
      if (current == 'Customers Paying Memo') {
        final rebuilt = PaymentMemoTotals.recalculateLedger(
          list.map((memo) => memo.values).toList(),
        );
        records[current] = rebuilt.map((values) => Record(values)).toList();
      }
    });
    await _save();
  }

  Future<void> _remove() async {
    final list = records[current]!;
    if (selected < 0 || selected >= list.length) {
      _snack('Select a record first.'); return;
    }
    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Remove record?'),
        content: const Text('This record will be deleted from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove')),
        ],
      ));
    if (yes == true) {
      setState(() {
        list.removeAt(selected);
        selected = -1;
        if (current == 'Customers Paying Memo') {
          final rebuilt = PaymentMemoTotals.recalculateLedger(
            list.map((memo) => memo.values).toList(),
          );
          records[current] = rebuilt.map((values) => Record(values)).toList();
        }
      });
      await _save();
    }
  }

  DateTimeRange _defaultReportRange(String section) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (section == 'Weekly Report') {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return DateTimeRange(start: start, end: start.add(const Duration(days: 6)));
    }
    if (section == 'Annual Report') {
      return DateTimeRange(
        start: DateTime(today.year, 1, 1),
        end: DateTime(today.year, 12, 31),
      );
    }
    return DateTimeRange(
      start: DateTime(today.year, today.month, 1),
      end: DateTime(today.year, today.month + 1, 0),
    );
  }

  DateTimeRange _activeReportRange() {
    final fallback = _defaultReportRange(
      current.contains('Report') ? current : 'Monthly Report',
    );
    return DateTimeRange(
      start: reportFrom ?? fallback.start,
      end: reportTo ?? fallback.end,
    );
  }

  List<Record> _recordsInPeriod(String section) {
    final range = _activeReportRange();
    return (records[section] ?? []).where((record) =>
      BusinessReporting.isWithinPeriod(
        record.values,
        start: range.start,
        end: range.end,
      )).toList();
  }

  double _periodSum(String section, String amountField) {
    final range = _activeReportRange();
    final data = (records[section] ?? []).map((record) => record.values).toList();
    return BusinessReporting.sumAmount(
      data,
      amountField: amountField,
      start: range.start,
      end: range.end,
    );
  }

  double _customerOutstanding(Record customer) {
    final customerId = (customer.values['Customer ID'] ?? '').trim();
    final totalPrice = double.tryParse(
      (customer.values['Total Price'] ?? '0').replaceAll(',', '').trim(),
    ) ?? 0;
    final ledger = (records['Customers Paying Memo'] ?? [])
      .map((record) => record.values).toList();
    final paid = PaymentMemoTotals.totalPaidForCustomer(
      ledger: ledger,
      customerId: customerId,
    );
    return totalPrice - paid;
  }

  String _reportText() {
    final range = _activeReportRange();
    final income = _periodSum('Daily Income Vouchers', 'Amount');
    final expenses = _periodSum('Daily Expense Vouchers', 'Amount');
    final customerPayments = _periodSum('Customers Paying Memo', 'Current Paid');
    final salaryPayable = _periodSum('Monthly Salary', 'Net Payable');
    final outstanding = (records['Customers'] ?? []).fold<double>(
      0, (sum, customer) => sum + _customerOutstanding(customer));
    final transactions = _recordsInPeriod('Daily Income Vouchers').length +
      _recordsInPeriod('Daily Expense Vouchers').length +
      _recordsInPeriod('Customers Paying Memo').length +
      _recordsInPeriod('Monthly Salary').length;
    final periodLabel = DateFormat('dd MMM yyyy').format(range.start) +
      ' — ' + DateFormat('dd MMM yyyy').format(range.end);

    return 'SOFTLAND BUSINESS SUMMARY\n'
      'Land, Real Estate & Developer Firm\n'
      'A symbol of reliance to fulfill your dreams\n\n'
      'Report: $current\n'
      'Period: $periodLabel\n\n'
      'Employee profiles: \${records['Employees']?.length ?? 0}\n'
      'Customer profiles: \${records['Customers']?.length ?? 0}\n'
      'Transactions in period: $transactions\n\n'
      'Daily income: ৳\${income.toStringAsFixed(2)}\n'
      'Daily expenses: ৳\${expenses.toStringAsFixed(2)}\n'
      'Net income less expenses: ৳\${(income - expenses).toStringAsFixed(2)}\n'
      'Customer payments received: ৳\${customerPayments.toStringAsFixed(2)}\n'
      'Salary payable: ৳\${salaryPayable.toStringAsFixed(2)}\n'
      'Current customer outstanding: ৳\${outstanding.toStringAsFixed(2)}\n\n'
      'Generated: \${DateFormat('dd MMM yyyy').format(DateTime.now())}';
  }

  Future<void> _pickReportDate({required bool chooseStart}) async {
    final range = _activeReportRange();
    final picked = await showDatePicker(
      context: context,
      initialDate: chooseStart ? range.start : range.end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (chooseStart) {
        reportFrom = DateTime(picked.year, picked.month, picked.day);
        if (reportTo != null && reportTo!.isBefore(reportFrom!)) {
          reportTo = reportFrom;
        }
      } else {
        reportTo = DateTime(picked.year, picked.month, picked.day);
        if (reportFrom != null && reportTo!.isBefore(reportFrom!)) {
          reportFrom = reportTo;
        }
      }
    });
  }

  void _resetReportRange() {
    final range = _defaultReportRange(current);
    setState(() {
      reportFrom = range.start;
      reportTo = range.end;
    });
  }

  Widget _reportFilters() {
    final range = _activeReportRange();
    final dateFormat = DateFormat('dd MMM yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => _pickReportDate(chooseStart: true),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text('From \${dateFormat.format(range.start)}'),
          ),
          OutlinedButton.icon(
            onPressed: () => _pickReportDate(chooseStart: false),
            icon: const Icon(Icons.event, size: 16),
            label: Text('To \${dateFormat.format(range.end)}'),
          ),
          TextButton.icon(
            onPressed: _resetReportRange,
            icon: const Icon(Icons.restart_alt, size: 16),
            label: const Text('Reset period'),
          ),
        ],
      ),
    );
  }

  String _salaryValue(Record record, String field, [String fallback = '—']) {
    final value = (record.values[field] ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  double _salaryNumber(Record record, String field) {
    return double.tryParse(
      (record.values[field] ?? '0').replaceAll(',', '').trim()) ?? 0;
  }

  String _money(Record record, String field) =>
      'BDT ${_salaryNumber(record, field).toStringAsFixed(2)}';

  pw.Widget _salaryInfoCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(width: 94, child: pw.Text(label,
          style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF52647A)))),
        pw.Expanded(child: pw.Text(value,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
      ]),
    );
  }

  pw.Widget _salarySectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
      color: PdfColor.fromInt(0xFFEAF0FA),
      child: pw.Text(title.toUpperCase(),
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF102D55))),
    );
  }

  pw.Widget _salaryAmountTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Salary component', 'Amount (BDT)'],
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromInt(0xFFFFFFFF)),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF173F78)),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(
          color: PdfColor.fromInt(0xFFDCE3ED), width: 0.5),
        bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFDCE3ED), width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.35),
      },
      cellAlignments: {
        1: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildSalarySlip(Record r) {
    final earnings = <List<String>>[
      ['Basic Salary', _money(r, 'Basic Salary')],
      ['House Rent', _money(r, 'House Rent')],
      ['Medical Allowance', _money(r, 'Medical')],
      ['Conveyance Allowance', _money(r, 'Conveyance')],
      ['Special Allowance', _money(r, 'Special Allowance')],
      ['Eid-ul-Fitr Bonus', _money(r, 'Eid-ul-Fitr Bonus')],
      ['Eid-ul-Azha Bonus', _money(r, 'Eid-ul-Azha Bonus')],
      ['Yearly Bonus', _money(r, 'Yearly Bonus')],
      ['Overtime Payment (manually entered)', _money(r, 'Overtime Amount (Manual Entry)')],
    ];
    final deductions = <List<String>>[
      ['Advance', _money(r, 'Advance')],
      ['Other Deduction', _money(r, 'Deduction')],
    ];
    final net = _salaryNumber(r, 'Net Payable');
    final total = _salaryNumber(r, 'Total Amount');

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFB9C7D9), width: 1.1),
      ),
      padding: const pw.EdgeInsets.all(17),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF102D55)),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 42, height: 42,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFFFFFFF), width: 1.5),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text('S', style: pw.TextStyle(
                  color: PdfColor.fromInt(0xFFFFFFFF), fontSize: 24,
                  fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('SOFTLAND', style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFFFFFFFF), fontSize: 21,
                    fontWeight: pw.FontWeight.bold)),
                  pw.Text('LAND, REAL ESTATE & DEVELOPER FIRM',
                    style: const pw.TextStyle(
                      color: PdfColor.fromInt(0xFFE1EAF7), fontSize: 8)),
                  pw.SizedBox(height: 3),
                  pw.Text('A symbol of reliance to fulfill your dreams',
                    style: const pw.TextStyle(
                      color: PdfColor.fromInt(0xFFD4E3F8), fontSize: 7.5)),
                ],
              )),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFBFD4F2))),
                child: pw.Text('MONTHLY\nSALARY SLIP',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(color: PdfColor.fromInt(0xFFFFFFFF),
                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 7),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('PAY PERIOD: ${_salaryValue(r, 'Salary Month')}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF173F78))),
          pw.Text('PAYMENT DATE: ${_salaryValue(r, 'Payment Date')}',
            style: const pw.TextStyle(fontSize: 8)),
        ]),
        _salarySectionTitle('Employee information'),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Column(children: [
            _salaryInfoCell('Employee name', _salaryValue(r, 'Employee Name')),
            _salaryInfoCell('Employee ID', _salaryValue(r, 'Employee ID')),
            _salaryInfoCell('Designation', _salaryValue(r, 'Designation')),
          ])),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Column(children: [
            _salaryInfoCell('Department', _salaryValue(r, 'Department')),
            _salaryInfoCell('Phone number', _salaryValue(r, 'Phone Number')),
            _salaryInfoCell('Address', _salaryValue(r, 'Employee Address')),
          ])),
        ]),
        _salarySectionTitle('Attendance & overtime'),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColor.fromInt(0xFFDCE3ED), width: 0.5),
          children: [
            pw.TableRow(children: [
              _attendanceCell('Working days', _salaryValue(r, 'Total Working Days', '0')),
              _attendanceCell('Present days', _salaryValue(r, 'Present Days', '0')),
              _attendanceCell('Absent days', _salaryValue(r, 'Absent Days', '0')),
              _attendanceCell('Overtime hours', _salaryValue(r, 'Overtime Hours', '0')),
            ]),
          ],
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            'Attendance is recorded for reference only and does not reduce basic salary. '
            'Overtime payment is entered manually.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFF53657A)),
          ),
        ),
        _salarySectionTitle('Earnings'),
        _salaryAmountTable(earnings),
        pw.SizedBox(height: 7),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Container(width: 205, padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5FB),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFDCE3ED))),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL EARNINGS',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('BDT ${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ])),
        ]),
        _salarySectionTitle('Deductions'),
        _salaryAmountTable(deductions),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: PdfColor.fromInt(0xFF173F78),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('NET SALARY PAYABLE',
                style: pw.TextStyle(color: PdfColor.fromInt(0xFFFFFFFF),
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('BDT ${net.toStringAsFixed(2)}',
                style: pw.TextStyle(color: PdfColor.fromInt(0xFFFFFFFF),
                  fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ]),
        ),
        if (_salaryValue(r, 'Payment Reference', '').isNotEmpty)
          pw.Padding(padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Text('Payment reference: ${_salaryValue(r, 'Payment Reference')}',
              style: const pw.TextStyle(fontSize: 7.5))),
        pw.SizedBox(height: 22),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _signatureBlock('EMPLOYEE SIGNATURE',
              _salaryValue(r, 'Employee Signature', ''), 125),
            _signatureBlock('AUTHORIZED SIGNATURE',
              _salaryValue(r, 'Authorized Signature', ''), 125),
            pw.Container(
              width: 105, height: 62,
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFF9EACC0))),
              child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('COMPANY STAMP',
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF52647A))),
                  pw.Expanded(child: pw.Center(child: pw.Text(
                    _salaryValue(r, 'Company Stamp', ''),
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8)))),
                ]),
            ),
          ]),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColor.fromInt(0xFFDCE3ED)),
        pw.Center(child: pw.Text(
          'This is a computer-generated salary statement. Please retain it for your records.',
          style: const pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFF718096)))),
      ]),
    );
  }

  pw.Widget _buildPaymentMemo(Record r) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFB9C7D9), width: 1.1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
            color: PdfColor.fromInt(0xFF102D55),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 42,
                  height: 42,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFFFFFFFF), width: 1.5),
                  ),
                  child: pw.Text('S', style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFFFFFFFF),
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  )),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SOFTLAND', style: pw.TextStyle(
                      color: PdfColor.fromInt(0xFFFFFFFF),
                      fontSize: 21,
                      fontWeight: pw.FontWeight.bold,
                    )),
                    pw.Text('LAND, REAL ESTATE & DEVELOPER FIRM',
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFFE1EAF7), fontSize: 8)),
                    pw.SizedBox(height: 3),
                    pw.Text('A symbol of reliance to fulfill your dreams',
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFFD4E3F8), fontSize: 7.5)),
                  ],
                )),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text('CUSTOMER PAYMENT MEMO',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF173F78),
            ))),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Memo No: \${_salaryValue(r, 'Memo Number')}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('Payment Date: \${_salaryValue(r, 'Payment Date')}',
                style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          _salarySectionTitle('Customer & property information'),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: pw.Column(children: [
              _salaryInfoCell('Customer name', _salaryValue(r, 'Customer Name')),
              _salaryInfoCell('Customer ID', _salaryValue(r, 'Customer ID')),
              _salaryInfoCell('Project / property', _salaryValue(r, 'Project / Property')),
            ])),
            pw.SizedBox(width: 12),
            pw.Expanded(child: pw.Column(children: [
              _salaryInfoCell('Plot / Flat', _salaryValue(r, 'Plot / Flat')),
              _salaryInfoCell('Payment method', _salaryValue(r, 'Payment Method')),
              _salaryInfoCell('Received by', _salaryValue(r, 'Received By')),
            ])),
          ]),
          _salarySectionTitle('Payment statement'),
          pw.TableHelper.fromTextArray(
            headers: const ['Payment particulars', 'Amount (BDT)'],
            data: [
              ['Total property price', _money(r, 'Total Price')],
              ['Previous paid', _money(r, 'Previous Paid')],
              ['Current payment received', _money(r, 'Current Paid')],
              ['Total paid to date', _money(r, 'Total Paid')],
              ['Remaining balance', _money(r, 'Remaining Balance')],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFFFFFFFF),
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF173F78)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8, vertical: 7),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(
                color: PdfColor.fromInt(0xFFDCE3ED), width: 0.5),
              bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFFDCE3ED), width: 0.5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.4),
            },
            cellAlignments: {1: pw.Alignment.centerRight},
          ),
          if (_salaryValue(r, 'Remarks', '').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text('Remarks: \${_salaryValue(r, 'Remarks')}',
                style: const pw.TextStyle(fontSize: 8)),
            ),
          pw.SizedBox(height: 28),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signatureBlock('CUSTOMER SIGNATURE',
                _salaryValue(r, 'Customer Signature', ''), 125),
              _signatureBlock('AUTHORIZED SIGNATURE',
                _salaryValue(r, 'Authorized Signature', ''), 125),
              pw.Container(
                width: 105,
                height: 62,
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromInt(0xFF9EACC0))),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('COMPANY STAMP',
                      style: pw.TextStyle(fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF52647A))),
                    pw.Expanded(child: pw.Center(child: pw.Text(
                      _salaryValue(r, 'Company Stamp', ''),
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8),
                    ))),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColor.fromInt(0xFFDCE3ED)),
          pw.Center(child: pw.Text(
            'Please retain this memo as proof of payment.',
            style: const pw.TextStyle(
              fontSize: 7.5, color: PdfColor.fromInt(0xFF718096))),
          ),
        ],
      ),
    );
  }

  pw.Widget _attendanceCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: pw.Column(children: [
        pw.Text(value, style: pw.TextStyle(
          fontSize: 11, fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF173F78))),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
      ]),
    );
  }

  pw.Widget _signatureBlock(String label, String value, double width) {
    return pw.SizedBox(width: width, child: pw.Column(children: [
      pw.SizedBox(height: 25, child: pw.Center(child: pw.Text(value,
        style: const pw.TextStyle(fontSize: 8)))),
      pw.Container(height: 0.7, color: PdfColor.fromInt(0xFF52647A)),
      pw.SizedBox(height: 4),
      pw.Text(label, textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF52647A))),
    ]));
  }

  Future<void> _print() async {
    if (current == 'Customers Paying Memo') {
      final memoRecords = records[current] ?? [];
      if (memoRecords.isEmpty) {
        _snack('Add a customer payment memo before printing.');
        return;
      }
      final chosen = selected >= 0 && selected < memoRecords.length
        ? [memoRecords[selected]] : memoRecords;
      final doc = pw.Document();
      for (final memo in chosen) {
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => _buildPaymentMemo(memo),
        ));
      }
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
      return;
    }
    if (current == 'Monthly Salary') {
      final salaryRecords = records[current] ?? [];
      if (salaryRecords.isEmpty) {
        _snack('Add a monthly salary record before printing.');
        return;
      }
      final chosen = selected >= 0 && selected < salaryRecords.length
        ? [salaryRecords[selected]] : salaryRecords;
      final doc = pw.Document();
      for (final record in chosen) {
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => _buildSalarySlip(record),
        ));
      }
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
      return;
    }

    final list = current == 'Home' || current.contains('Report')
      ? <Record>[] : records[current]!;
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(build: (_) => [
      pw.Text('SOFTLAND', style: pw.TextStyle(
        fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.Text('Land, Real Estate & Developer Firm'),
      pw.Text('A symbol of reliance to fulfill your dreams'),
      pw.SizedBox(height: 16),
      pw.Text(current, style: pw.TextStyle(
        fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      if (current.contains('Report') || current == 'Home')
        pw.Text(_reportText())
      else if (list.isEmpty)
        pw.Text('No records available.')
      else
        pw.TableHelper.fromTextArray(
          headers: fieldsFor(current),
          data: list.map((r) => fieldsFor(current)
            .map((f) => r.values[f] ?? '').toList()).toList(),
        ),
    ]));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
  Future<void> _share() async {
    if (current.contains('Report') || current == 'Home') {
      await Share.share(_reportText());
      return;
    }
    final list = records[current]!;
    if (current == 'Customers Paying Memo' && selected >= 0 && selected < list.length) {
      final r = list[selected];
      final lines = <String>[
        'SOFTLAND — CUSTOMER PAYMENT MEMO',
        'Land, Real Estate & Developer Firm',
        'A symbol of reliance to fulfill your dreams',
        'Memo number: ${r.values['Memo Number'] ?? ''}',
        'Payment date: ${r.values['Payment Date'] ?? ''}',
        'Customer: ${r.values['Customer Name'] ?? ''}',
        'Customer ID: ${r.values['Customer ID'] ?? ''}',
        'Project / property: ${r.values['Project / Property'] ?? ''}',
        'Plot / Flat: ${r.values['Plot / Flat'] ?? ''}',
        'Total price: BDT ${r.values['Total Price'] ?? '0'}',
        'Previous paid: BDT ${r.values['Previous Paid'] ?? '0'}',
        'Current payment: BDT ${r.values['Current Paid'] ?? '0'}',
        'Total paid: BDT ${r.values['Total Paid'] ?? '0'}',
        'Remaining balance: BDT ${r.values['Remaining Balance'] ?? '0'}',
        'Payment method: ${r.values['Payment Method'] ?? ''}',
        'Received by: ${r.values['Received By'] ?? ''}',
        'Customer signature: ${r.values['Customer Signature'] ?? ''}',
        'Authorized signature: ${r.values['Authorized Signature'] ?? ''}',
        'Company stamp: ${r.values['Company Stamp'] ?? ''}',
        'Remarks: ${r.values['Remarks'] ?? ''}',
      ];
      await Share.share(lines.join('\\n'));
      return;
    }
    if (current == 'Monthly Salary' && selected >= 0 && selected < list.length) {
      final r = list[selected];
      final lines = <String>[
        'SOFTLAND — MONTHLY SALARY SLIP',
        'Land, Real Estate & Developer Firm',
        'A symbol of reliance to fulfill your dreams',
        'Employee: ${r.values['Employee Name'] ?? ''}',
        'Employee ID: ${r.values['Employee ID'] ?? ''}',
        'Designation: ${r.values['Designation'] ?? ''}',
        'Department: ${r.values['Department'] ?? ''}',
        'Salary month: ${r.values['Salary Month'] ?? ''}',
        'Working / Present / Absent days: ${r.values['Total Working Days'] ?? '0'} / ${r.values['Present Days'] ?? '0'} / ${r.values['Absent Days'] ?? '0'}',
        'Overtime hours: ${r.values['Overtime Hours'] ?? '0'}',
        'Basic salary: BDT ${r.values['Basic Salary'] ?? '0'}',
        'House rent: BDT ${r.values['House Rent'] ?? '0'}',
        'Medical: BDT ${r.values['Medical'] ?? '0'}',
        'Conveyance: BDT ${r.values['Conveyance'] ?? '0'}',
        'Special allowance: BDT ${r.values['Special Allowance'] ?? '0'}',
        'Eid-ul-Fitr bonus: BDT ${r.values['Eid-ul-Fitr Bonus'] ?? '0'}',
        'Eid-ul-Azha bonus: BDT ${r.values['Eid-ul-Azha Bonus'] ?? '0'}',
        'Yearly bonus: BDT ${r.values['Yearly Bonus'] ?? '0'}',
        'Manual overtime payment: BDT ${r.values['Overtime Amount (Manual Entry)'] ?? '0'}',
        'Total amount: BDT ${r.values['Total Amount'] ?? '0'}',
        'Advance: BDT ${r.values['Advance'] ?? '0'}',
        'Deduction: BDT ${r.values['Deduction'] ?? '0'}',
        'NET PAYABLE: BDT ${r.values['Net Payable'] ?? '0'}',
        'Employee signature: ${r.values['Employee Signature'] ?? ''}',
        'Authorized signature: ${r.values['Authorized Signature'] ?? ''}',
        'Company stamp: ${r.values['Company Stamp'] ?? ''}',
      ];
      await Share.share(lines.join('\n'));
      return;
    }
    final text = 'SOFTLAND — $current\n' + list.map((r) =>
      fieldsFor(current).map((f) => '$f: ${r.values[f] ?? ''}')
        .join(' | ')).join('\n');
    await Share.share(text.isEmpty ? 'SOFTLAND Business Management System' : text);
  }
  void _open(String item) {
    Navigator.of(context).maybePop();
    setState(() {
      current = item;
      selected = -1;
      if (item.contains('Report')) {
        final range = _defaultReportRange(item);
        reportFrom = range.start;
        reportTo = range.end;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHome = current == 'Home';
    return Scaffold(
      drawer: Drawer(child: SafeArea(child: Column(children: [
        Container(width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
          color: const Color(0xFFDDF18A),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SOFTLAND', style: TextStyle(fontSize: 27,
                fontWeight: FontWeight.w900, color: Color(0xFF102D55))),
              SizedBox(height: 5),
              Text('Land, Real Estate & Developer Firm',
                style: TextStyle(fontWeight: FontWeight.w600)),
              Text('A symbol of reliance to fulfill your dreams',
                style: TextStyle(fontSize: 11)),
            ])),
        Expanded(child: ListView(children: menuItems.map((m) => ListTile(
          leading: Icon(_iconFor(m),
            color: current == m ? const Color(0xFF245DB5) : Colors.blueGrey),
          title: Text(m, style: TextStyle(fontWeight:
            current == m ? FontWeight.bold : FontWeight.normal)),
          selected: current == m, onTap: () => _open(m),
        )).toList())),
        const Divider(),
        ListTile(leading: const Icon(Icons.close), title: const Text('Close menu'),
          onTap: () => Navigator.pop(context)),
      ]))),
      appBar: AppBar(
        leading: Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, size: 29),
          onPressed: () => Scaffold.of(ctx).openDrawer())),
        title: Text(isHome ? 'SOFTLAND' : current,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [if (!isHome) IconButton(tooltip: 'Save', onPressed: _save,
          icon: const Icon(Icons.save_outlined))],
      ),
      body: !loaded ? const Center(child: CircularProgressIndicator()) :
        isHome ? _home() : _page(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: isHome ? 0 : current == 'Employees' ? 1 :
          current == 'Customers' ? 2 : 0,
        onDestinationSelected: (i) => _open(
          i == 0 ? 'Home' : i == 1 ? 'Employees' : 'Customers'),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Employees'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Customers'),
        ],
      ),
    );
  }

  Widget _home() {
    final total = records.values.fold<int>(0, (a, b) => a + b.length);
    final tiles = [
      ('Employees', 'Employee profiles', const Color(0xFFE6EEFF), const Color(0xFF2860C6)),
      ('Customers', 'Customer information', const Color(0xFFE8F5EC), const Color(0xFF27834D)),
      ('Customers Paying Memo', 'Customer payment records', const Color(0xFFFFF1E2), const Color(0xFFD77B16)),
      ('Monthly Salary', 'Salary calculations', const Color(0xFFF0EAFE), const Color(0xFF8051C6)),
      ('Daily Income Vouchers', 'Income records', const Color(0xFFE6F4F7), const Color(0xFF23899A)),
      ('Daily Expense Vouchers', 'Expense records', const Color(0xFFFCEAF1), const Color(0xFFC43B79)),
      ('Letterheads', 'Printable company letters', const Color(0xFFEAF0F8), const Color(0xFF315D91)),
      ('Weekly Report', 'Weekly business summary', const Color(0xFFE8F5EC), const Color(0xFF27834D)),
      ('Monthly Report', 'Monthly business summary', const Color(0xFFEAF0F8), const Color(0xFF315D91)),
      ('Annual Report', 'Annual business summary', const Color(0xFFFCEAF1), const Color(0xFFC43B79)),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFFDDF18A), Color(0xFFC8EB69)]),
        borderRadius: BorderRadius.circular(22)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SOFTLAND', style: TextStyle(fontSize: 29,
              fontWeight: FontWeight.w900, color: Color(0xFF102D55))),
            Text('LAND, REAL ESTATE & DEVELOPER FIRM',
              style: TextStyle(fontWeight: FontWeight.w700,
                color: Color(0xFF102D55))),
            SizedBox(height: 5),
            Text('A symbol of reliance to fulfill your dreams',
              style: TextStyle(color: Color(0xFF174D91))),
          ])),
      const SizedBox(height: 18),
      GridView.count(shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.sizeOf(context).width > 760 ? 3 : 2,
        childAspectRatio: 1.25, crossAxisSpacing: 12, mainAxisSpacing: 12,
        children: tiles.map((t) => InkWell(
          borderRadius: BorderRadius.circular(18), onTap: () => _open(t.$1),
          child: Container(padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: t.$3,
              borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(t.$1), color: t.$4, size: 30),
                const Spacer(),
                Text(t.$1, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(t.$2, style: const TextStyle(
                  color: Colors.black54, fontSize: 12)),
                Align(alignment: Alignment.bottomRight,
                  child: CircleAvatar(radius: 16, backgroundColor: t.$4,
                    child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18))),
              ])),
        )).toList()),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Dashboard', style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(children: [
              _stat('Total records', '$total', Icons.folder_open),
              _stat('Employees', '${records['Employees']?.length ?? 0}/10',
                Icons.people),
              _stat('Customers', '${records['Customers']?.length ?? 0}',
                Icons.groups),
            ]),
            const SizedBox(height: 8),
            Text('Today: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              style: const TextStyle(color: Colors.black54)),
          ]))),
      const SizedBox(height: 10),
      const Text('Open the menu ☰ to access all 12 sections.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.blueGrey)),
    ]);
  }

  Widget _stat(String label, String value, IconData icon) =>
    Expanded(child: Column(children: [
      Icon(icon, color: const Color(0xFF245DB5)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(
        fontWeight: FontWeight.bold, fontSize: 20)),
      Text(label, style: const TextStyle(
        fontSize: 12, color: Colors.black54)),
    ]));

  Widget _page() {
    final list = records[current] ?? [];
    final report = current.contains('Report');
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Wrap(spacing: 8, runSpacing: 8,
          alignment: WrapAlignment.center, children: [
            _action('Add', Icons.add_circle_outline, const Color(0xFF2860C6),
              () => _editDialog()),
            _action('Edit', Icons.edit_outlined, const Color(0xFFB87818), () {
              if (selected < 0 || selected >= list.length) {
                _snack('Select a record first.'); return;
              }
              _editDialog(record: list[selected]);
            }),
            _action('Remove', Icons.delete_outline, const Color(0xFFC73742), _remove),
            _action('Save', Icons.save_outlined, const Color(0xFF23834C), _save),
            _action('Print', Icons.print_outlined, const Color(0xFF8051C6), _print),
            _action('Share', Icons.share_outlined, const Color(0xFF25849C), _share),
          ])),
      const Divider(),
      if (report) ...[
        _reportFilters(),
        Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Text(_reportText(), style: const TextStyle(height: 1.6))))),
      ],
      Padding(padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Text(current, style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold))),
          Text('${list.length} records',
            style: const TextStyle(color: Colors.blueGrey)),
        ])),
      Expanded(child: report ? const SizedBox.shrink() : list.isEmpty ? Center(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          Icon(_iconFor(current), size: 54, color: Colors.blueGrey.shade200),
          const SizedBox(height: 10), Text('No $current records yet.'),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: () => _editDialog(),
            icon: const Icon(Icons.add), label: const Text('Add first record')),
        ])) : ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          itemCount: list.length, itemBuilder: (ctx, i) {
            final r = list[i];
            final subtitle = [
              r.date,
              r.values['Details'] ?? r.values['Project / Property'] ?? '',
              r.values['Plot / Flat'] ?? '',
            ].where((x) => x.isNotEmpty).join(' • ');
            return Card(color: selected == i
              ? const Color(0xFFE5EEFF) : Colors.white,
              child: ListTile(
                onTap: () => setState(() => selected = i),
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(r.title, style: const TextStyle(
                  fontWeight: FontWeight.w600)),
                subtitle: Text(subtitle),
                trailing: current == 'Customers'
                  ? SizedBox(width: 112, child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Outstanding', style: TextStyle(
                          fontSize: 10, color: Colors.blueGrey)),
                        Text('৳${_customerOutstanding(r).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ))
                  : Text(r.amount.isEmpty ? '' : '৳${r.amount}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
              ));
          })),
    ]);
  }

  Widget _action(String label, IconData icon, Color color,
      VoidCallback onTap) => SizedBox(width: 104,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10)),
      onPressed: onTap, child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21), const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12)),
        ])));

  IconData _iconFor(String name) {
    switch (name) {
      case 'Home': return Icons.home_outlined;
      case 'Employees': return Icons.people_outline;
      case 'Customers': return Icons.groups_outlined;
      case 'Customers Paying Memo': return Icons.receipt_long_outlined;
      case 'Monthly Salary': return Icons.account_balance_wallet_outlined;
      case 'Daily Income Vouchers': return Icons.south_west;
      case 'Daily Expense Vouchers': return Icons.north_east;
      case 'Letterheads': return Icons.description_outlined;
      case 'Contact Information': return Icons.contact_phone_outlined;
      case 'Weekly Report': return Icons.calendar_view_week;
      case 'Monthly Report': return Icons.calendar_month;
      case 'Annual Report': return Icons.bar_chart;
      default: return Icons.folder_outlined;
    }
  }
}

class RecordFormDialog extends StatefulWidget {
  final String section;
  final Map<String, String> initial;
  final List<Record> employees;
  final List<Record> customers;
  final List<Record> existingMemos;

  const RecordFormDialog({
    super.key,
    required this.section,
    required this.initial,
    required this.employees,
    required this.customers,
    required this.existingMemos,
  });

  @override
  State<RecordFormDialog> createState() => _RecordFormDialogState();
}

class _RecordFormDialogState extends State<RecordFormDialog> {
  final Map<String, TextEditingController> controllers = {};
  final formKey = GlobalKey<FormState>();
  String? selectedEmployeeId;
  String? selectedCustomerId;

  bool get salary => widget.section == 'Monthly Salary';
  bool get employeeForm => widget.section == 'Employees';
  bool get customerForm => widget.section == 'Customers';
  bool get memo => widget.section == 'Customers Paying Memo';

  bool get hasSelectableEmployees => widget.employees.any(
    (r) => (r.values['Employee ID'] ?? '').trim().isNotEmpty);
  bool get hasSelectableCustomers => widget.customers.any(
    (r) => (r.values['Customer ID'] ?? '').trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    for (final field in fieldsFor(widget.section)) {
      controllers[field] = TextEditingController(
        text: widget.initial[field] ?? '',
      );
    }

    if (employeeForm) {
      controllers['Employee ID']!.text =
        controllers['Phone Number']!.text.trim();
    }
    if (customerForm) {
      controllers['Customer ID']!.text =
        controllers['Phone Number']!.text.trim();
    }
    if (salary) {
      final id = controllers['Employee ID']!.text.trim();
      selectedEmployeeId = id.isEmpty ? null : id;
      _recalculate();
    }
    if (memo) {
      final id = controllers['Customer ID']!.text.trim();
      selectedCustomerId = id.isEmpty ? null : id;
      if (widget.initial.isEmpty) {
        controllers['Memo Number']!.text = _nextMemoNumber();
      }
      if (controllers['Payment Date']!.text.trim().isEmpty) {
        controllers['Payment Date']!.text = DateFormat('dd MMM yyyy').format(DateTime.now());
      }
      _recalculateMemo();
    }
  }

  double _n(String key) => double.tryParse(
    (controllers[key]?.text ?? '0').replaceAll(',', '').trim(),
  ) ?? 0;

  String _nextMemoNumber() {
    final prefix = 'CPM-' + DateFormat('yyyyMM').format(DateTime.now()) + '-';
    var largest = 0;
    for (final record in widget.existingMemos) {
      final value = (record.values['Memo Number'] ?? '').trim();
      if (!value.startsWith(prefix)) continue;
      final number = int.tryParse(value.substring(prefix.length)) ?? 0;
      if (number > largest) largest = number;
    }
    return prefix + (largest + 1).toString().padLeft(4, '0');
  }

  void _recalculate() {
    if (!salary) return;
    final totals = PayrollTotals.fromValues({
      for (final entry in controllers.entries)
        entry.key: entry.value.text,
    });
    controllers['Total Amount']!.text = totals.totalAmount.toStringAsFixed(2);
    controllers['Net Payable']!.text = totals.netPayable.toStringAsFixed(2);
  }

  void _recalculateMemo() {
    if (!memo) return;
    final customerId = controllers['Customer ID']!.text.trim();
    final ledger = widget.existingMemos.map((record) => record.values).toList();
    final memoNumber = controllers['Memo Number']!.text.trim();
    final previous = PaymentMemoTotals.previousPaidFromLedger(
      ledger: ledger,
      customerId: customerId,
      stopBeforeMemoNumber: widget.initial.isNotEmpty ? memoNumber : null,
    );
    final totals = PaymentMemoTotals.calculate(
      totalPrice: _n('Total Price'),
      previousPaid: previous,
      currentPaid: _n('Current Paid'),
    );
    controllers['Previous Paid']!.text = totals.previousPaid.toStringAsFixed(2);
    controllers['Total Paid']!.text = totals.totalPaid.toStringAsFixed(2);
    controllers['Remaining Balance']!.text = totals.remainingBalance.toStringAsFixed(2);
  }

  void _fillEmployee(Record employee) {
    final v = employee.values;
    controllers['Employee Name']!.text = v['Employee Name'] ?? '';
    controllers['Employee ID']!.text = v['Employee ID'] ?? '';
    controllers['Designation']!.text = v['Designation'] ?? '';
    controllers['Department']!.text = v['Department'] ?? '';
    controllers['Phone Number']!.text = v['Phone Number'] ?? '';
    controllers['Employee Address']!.text = v['Address'] ?? '';
    controllers['Basic Salary']!.text = v['Basic Salary'] ?? '0';
    selectedEmployeeId = v['Employee ID'];
    _recalculate();
    setState(() {});
  }

  void _fillCustomer(Record customer) {
    final v = customer.values;
    controllers['Customer Name']!.text = v['Customer Name'] ?? '';
    controllers['Customer ID']!.text = v['Customer ID'] ?? '';
    controllers['Project / Property']!.text = v['Project / Property'] ?? '';
    controllers['Plot / Flat']!.text = v['Plot / Flat'] ?? '';
    controllers['Total Price']!.text = v['Total Price'] ?? '0';
    selectedCustomerId = v['Customer ID'];
    _recalculateMemo();
    setState(() {});
  }

  Widget _employeePicker() {
    final employees = widget.employees.where(
      (r) => (r.values['Employee ID'] ?? '').trim().isNotEmpty,
    ).toList();
    if (employees.isEmpty) return const SizedBox.shrink();
    final ids = employees.map((r) => r.values['Employee ID']!).toSet();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: ids.contains(selectedEmployeeId) ? selectedEmployeeId : null,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Select saved employee'),
        items: employees.map((employee) {
          final id = employee.values['Employee ID']!;
          final name = employee.values['Employee Name'] ?? 'Employee';
          return DropdownMenuItem<String>(
            value: id,
            child: Text(name + ' (' + id + ')',
              overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (id) {
          if (id == null) return;
          for (final employee in employees) {
            if (employee.values['Employee ID'] == id) {
              _fillEmployee(employee);
              break;
            }
          }
        },
      ),
    );
  }

  Widget _customerPicker() {
    final customers = widget.customers.where(
      (r) => (r.values['Customer ID'] ?? '').trim().isNotEmpty,
    ).toList();
    if (customers.isEmpty) return const SizedBox.shrink();
    final ids = customers.map((r) => r.values['Customer ID']!).toSet();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: ids.contains(selectedCustomerId) ? selectedCustomerId : null,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Select saved customer'),
        items: customers.map((customer) {
          final id = customer.values['Customer ID']!;
          final name = customer.values['Customer Name'] ?? 'Customer';
          return DropdownMenuItem<String>(
            value: id,
            child: Text(name + ' (' + id + ')',
              overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (id) {
          if (id == null) return;
          for (final customer in customers) {
            if (customer.values['Customer ID'] == id) {
              _fillCustomer(customer);
              break;
            }
          }
        },
      ),
    );
  }

  bool _isReadOnly(String field) {
    if (salary && (field == 'Total Amount' || field == 'Net Payable')) {
      return true;
    }
    if (employeeForm && field == 'Employee ID') return true;
    if (customerForm && field == 'Customer ID') return true;
    if (memo && (field == 'Memo Number' || field == 'Previous Paid' ||
        field == 'Total Paid' || field == 'Remaining Balance')) {
      return true;
    }
    if (salary && field == 'Employee ID' && hasSelectableEmployees) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = fieldsFor(widget.section);
    return AlertDialog(
      title: Text(widget.initial.isEmpty
        ? 'Add ' + widget.section + ' record'
        : 'Edit ' + widget.section + ' record'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (salary) ...[
                  if (hasSelectableEmployees) _employeePicker(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Attendance is for record only. Basic salary is not reduced. '
                      'Enter overtime payment manually.',
                      style: TextStyle(color: Color(0xFF173F78)),
                    ),
                  ),
                ],
                if (memo && hasSelectableCustomers) _customerPicker(),
                ...fields.map((field) {
                  final readOnly = _isReadOnly(field);
                  final multiline = field == 'Address' ||
                    field == 'Employee Address' || field == 'Notes' ||
                    field == 'Letter Body' || field == 'Remarks';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: controllers[field],
                      readOnly: readOnly,
                      onChanged: (value) {
                        if (salary && !readOnly) _recalculate();
                        if (memo && [
                          'Total Price', 'Previous Paid', 'Current Paid',
                        ].contains(field)) {
                          _recalculateMemo();
                        }
                        if (employeeForm && field == 'Phone Number') {
                          controllers['Employee ID']!.text = value.trim();
                        }
                        if (customerForm && field == 'Phone Number') {
                          controllers['Customer ID']!.text = value.trim();
                        }
                      },
                      keyboardType: isNumericField(field)
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                      maxLines: multiline ? 3 : 1,
                      decoration: InputDecoration(
                        labelText: field,
                        suffixText: readOnly
                          ? (memo && field == 'Memo Number' ? 'Auto number' : 'Auto')
                          : null,
                        filled: readOnly,
                        fillColor: readOnly
                          ? const Color(0xFFEAF1FF)
                          : Colors.white,
                      ),
                      validator: (value) {
                        final requiredFields = <String>{
                          'Employee Name', 'Employee ID', 'Customer Name',
                          'Customer ID', 'Memo Number', 'Voucher Number',
                        };
                        if ((requiredFields.contains(field) ||
                            ((employeeForm || customerForm) &&
                              field == 'Phone Number')) &&
                            (value == null || value.trim().isEmpty)) {
                          return 'This field is required';
                        }
                        if (isNumericField(field) &&
                            value != null && value.trim().isNotEmpty &&
                            double.tryParse(value.replaceAll(',', '')) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final result = <String, String>{
              for (final entry in controllers.entries)
                entry.key: entry.value.text.trim(),
            };
            Navigator.pop(context, result);
          },
          icon: const Icon(Icons.save),
          label: const Text('Save record'),
        ),
      ],
    );
  }
}
