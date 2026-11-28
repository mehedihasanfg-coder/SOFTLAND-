# SOFTLAND Business Management System

Flutter cross-platform application for Windows 10/11 and iPhone 12 (iOS), following the supplied SOFTLAND brand and layout references.

## Implemented source

- SOFTLAND dashboard with company name, working area and motto.
- Left navigation drawer with all 12 requested sections and a close action.
- Common Add, Edit, Remove, Save, Print and Share toolbar on every data section.
- Section-based CSV persistence: Employees.csv, Customers.csv, Customers_Paying_Memo.csv, Monthly_Salary.csv, Daily_Income_Vouchers.csv, Daily_Expense_Vouchers.csv, Letterheads.csv and Contact_Information.csv, plus report-section CSV files.
- Windows storage uses D:\\SOFTLAND first, then the first writable non-C drive from E: through Z:. The app never writes business records to C:. If no non-C drive is writable, it shows the required one-button error and closes after OK.
- iPhone storage uses the app Documents/SOFTLAND folder. Enable the two iOS file-sharing Info.plist keys in the setup guide so the CSVs appear in Files and can be opened with iSpreadsheet.
- Existing SharedPreferences records are migrated once into CSV files; ongoing business records are no longer saved to SharedPreferences.
- Employee profile limit: 10.
- Employee ID is automatically copied from the employee mobile number; duplicate mobile-based IDs are rejected.
- Customer ID is automatically copied from the customer mobile number; duplicate mobile-based IDs are rejected.
- Customer Paying Memo has an automatically generated monthly sequence number (CPM-YYYYMM-0001), customer lookup, automatically carried-forward Previous Paid, manually entered Current Paid, Total Paid and Remaining Balance.
- Customer payment history is maintained as an ordered local ledger. Editing or removing an earlier memo recalculates subsequent Previous Paid, Total Paid and Remaining Balance values for that customer.
- Customer list shows the current outstanding balance based on the customer property price and saved payment memos.
- Customer Paying Memo Print produces a branded A4 payment receipt with memo number/date, customer and property details, payment breakdown, balance, customer and authorized signature lines and company-stamp box. A selected memo prints alone; with no selection, all memos print as separate pages.
- Customer Paying Memo Share creates a structured shareable payment statement for the selected memo.
- Monthly Salary can select a saved employee and prefill employee identity, contact, designation and basic salary.
- Salary includes Basic Salary, attendance, manual overtime hours and amount, house rent, medical, conveyance, special allowance, Eid-ul-Fitr bonus, Eid-ul-Azha bonus, yearly bonus, advance and deduction.
- Attendance never reduces Basic Salary.
- Total Amount is the sum of the salary components plus the manually entered overtime amount.
- Net Payable is Total Amount minus Advance and Deduction.
- Dedicated A4 SOFTLAND salary slip with employee details, attendance, earnings, deductions, net payable, signature lines and company-stamp box.
- Salary print outputs the selected employee's slip, or all salary records when none is selected.
- Weekly, Monthly and Annual reports have default week/month/year ranges plus editable From/To date filters. Reports summarize date-filtered income, expenses, customer payments and salary payable, with current customer receivables shown separately.

## Tests added

Test coverage includes:

- `test/payroll_calculator_test.dart`: attendance does not reduce Basic Salary; manual overtime and all specified salary components are included; Advance and Deduction are subtracted; comma-separated monetary values are parsed.
- `test/payment_memo_calculator_test.dart`: customer-specific previous-payment carry-forward; editing an earlier memo excludes later payments from its previous-paid amount; total and remaining balance calculations; recalculation of later ledger entries; legacy memo compatibility.
- `test/business_reporting_test.dart`: supported date formats, inclusive report boundaries and date-filtered amount totals.
- `test/records_storage_csv_test.dart`: CSV round-trip preserves leading-zero mobile numbers and commas in names.

## Current limitations

- Flutter and Dart were not available in the authoring environment. The source and tests have been committed, but compilation, test execution and device testing have not been performed.
- Reports currently provide date-filtered aggregate totals, not full transaction-by-transaction ledgers or downloadable spreadsheet exports. Date filters use the saved Date, Payment Date, Letter Date or Salary Month fields; records with unparseable or empty dates are excluded from period totals.
- Customer payment history follows the order in which memos are saved. Backdated payments should be entered in chronological order for the cumulative Previous Paid figures to remain intuitive.
- Letterheads need full branded composition and signature/stamp image support.
- Salary slip signature and stamp fields currently accept typed text and provide printable blank areas; image upload is not implemented.
- Data is local to each device. Cloud sync, multi-user access, automated backups, role permissions and a formal encryption/retention policy remain future work.
- The Windows PowerShell drive preflight is provided at `scripts/check_database_drive.ps1`, but it has not yet been wired into a finished installer. The app's own startup check is implemented; a production installer must invoke the preflight before installing.
- iOS Files visibility requires the `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` keys described in `docs/ios_files_app_setup.md`. The iOS runner folder has not yet been generated in this repository.
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
