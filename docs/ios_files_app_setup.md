# Enable SOFTLAND CSV files in the iPhone Files app

The Flutter application stores iPhone records under the app's Documents/SOFTLAND folder. To make those files visible in Files and available to iSpreadsheet:

1. Generate the iOS runner if it is not present:

   flutter create --platforms=windows,ios .

2. Open ios/Runner/Info.plist.
3. Add these keys inside the top-level dict:

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

4. Set CFBundleDisplayName to SOFTLAND so the app is easy to identify in Files:

```xml
<key>CFBundleDisplayName</key>
<string>SOFTLAND</string>
```

5. Build and install the app on the iPhone.
6. Open Files → On My iPhone → SOFTLAND → SOFTLAND.
7. Open the required CSV file with iSpreadsheet.

The application writes one CSV file per section. Mobile IDs are kept as text so leading zeroes are preserved. If a CSV is edited externally in iSpreadsheet while SOFTLAND is closed, the next SOFTLAND launch reads the updated file. Avoid editing the same file in both apps at the same time.

A signed iOS build still requires macOS, Xcode and the appropriate Apple signing configuration.