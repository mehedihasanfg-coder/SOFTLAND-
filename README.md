# SOFTLAND Business Management System

Flutter cross-platform application for Windows 10/11 and iPhone 12 (iOS), following the supplied SOFTLAND brand and layout references.

## Implemented source

- SOFTLAND dashboard with company name, working area and motto.
- Left navigation drawer with all 12 requested sections and a close action.
- Common Add, Edit, Remove, Save, Print and Share toolbar on every data section.
- Local on-device persistence with SharedPreferences.
- Employee profile limit: 10.
- Employee ID is automatically copied from the employee mobile number; duplicate mobile-based IDs are rejected.
- Customer ID is automatically copied from the customer mobile number; duplicate mobile-based IDs are rejected.
- Customer Paying Memo has an automatically generated monthly sequence number (CPM-YYYYMM-0001), customer lookup, previous/current payment, automatically calculated total paid and remaining balance.
- Monthly Salary can select a saved employee and prefill employee identity, contact, designation and basic salary.
- Salary includes Basic Salary, attendance, manual overtime hours and amount, house rent, medical, conveyance, special allowance, Eid-ul-Fitr bonus, Eid-ul-Azha bonus, yearly bonus, advance and deduction.
- Attendance never reduces Basic Salary.
- Total Amount is the sum of the salary components plus the manually entered overtime amount.
- Net Payable is Total Amount minus Advance and Deduction.
- Dedicated A4 SOFTLAND salary slip with employee details, attendance, earnings, deductions, net payable, signature lines and company-stamp box.
- Salary print outputs the selected employee's slip, or all salary records when none is selected.
- Weekly, Monthly and Annual report pages currently show aggregate totals.

## Tests added

test/payroll_calculator_test.dart covers:
- Attendance does not reduce Basic Salary.
- Manual overtime and all specified salary components are included.
- Advance and Deduction are subtracted from Total Amount.
- Comma-separated monetary values are parsed.

## Current limitations

- Flutter and Dart were not available in the authoring environment. The source and tests have been committed, but compilation, test execution and device testing have not been performed.
- Weekly/Monthly/Annual reports still need date-filtered periods and detailed ledgers.
- Letterheads need full branded composition and signature/stamp image support.
- Salary slip signature and stamp fields currently accept typed text and provide printable blank areas; image upload is not implemented.
- Data is local to each device. Cloud sync, multi-user access, automated backups, role permissions and a formal encryption/retention policy remain future work.
- Windows executable and signed iOS IPA have not been built.

## Generate platform runners and run on Windows

This repository currently contains the shared Flutter source but does not yet include generated Windows/iOS runner folders. On a machine with Flutter installed, run this once from the repository root:

flutter create --platforms=windows,ios .

Then install Flutter's Windows desktop prerequisites and run:

flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter build windows

## Run/build for iPhone 12

Use macOS with Xcode and the required Apple signing setup. If the platform runners have not yet been generated, first run `flutter create --platforms=windows,ios .` from the project root. Then run:

flutter pub get
flutter test
flutter run -d ios
flutter build ipa
