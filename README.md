# SOFTLAND Business Management System

Flutter cross-platform starter for Windows 10/11 and iPhone 12 (iOS), based on the user's supplied SOFTLAND references.

## Implemented in this revision
- SOFTLAND home dashboard, brand banner and motto.
- Left navigation drawer with all 12 requested sections and close action.
- Dedicated data-entry fields for Employees, Customers, Customers Paying Memo, Monthly Salary, Daily Income Vouchers, Daily Expense Vouchers, Letterheads and Contact Information.
- Every section has Add, Edit, Remove, Save, Print and Share actions.
- Local on-device persistence using SharedPreferences.
- Employee record limit of 10.
- Monthly Salary form fields include Basic Salary, attendance counts, overtime hours, all specified allowances and bonuses, manually entered overtime amount, Advance, Deduction, Employee Signature, Authorized Signature and Company Stamp.
- Total Amount is calculated as salary components plus manually entered overtime amount.
- Net Payable is calculated as Total Amount minus Advance minus Deduction.
- Attendance counts do not change Basic Salary.
- Weekly, Monthly and Annual report pages show a current aggregate snapshot of saved employee, customer, income, expense and salary data.
- Legacy records from the first starter version are read during migration.

## Important limitations
- The salary calculation currently treats every listed allowance and bonus as an amount included in Total Amount. Confirm any company-specific bonus eligibility/proration rules before production payroll use.
- Weekly/Monthly/Annual reports currently show aggregate totals; date-filtered report periods and detailed ledgers are not yet implemented.
- Contact Information and Letterheads have dedicated data-entry fields, but branded letterhead composition and signature/stamp image handling remain future work.
- Data is stored locally on the device. Cloud sync, multi-user access, encryption policy, database backup/restore and role permissions are not implemented.
- This environment does not have Flutter or Dart installed, so the code has not been compiled or run here. Platform builds and device testing remain outstanding.

## Run on Windows
Install Flutter SDK and Windows desktop development prerequisites, then:
```bash
flutter pub get
flutter run -d windows
flutter build windows
```

## Run/build for iPhone 12
Use a Mac with Xcode and an Apple signing setup:
```bash
flutter pub get
flutter run -d ios
flutter build ipa
```
A signed iOS IPA requires the appropriate Apple developer signing configuration.
