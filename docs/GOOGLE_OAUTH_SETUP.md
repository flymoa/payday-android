# First Android connection: Google OAuth

The project uses only the **Payday fictional-data DEMO spreadsheet**.
The GitHub Actions APK is a **compile-only debug artifact** until OAuth is configured.

## Google Cloud configuration (one-time)

1. Visit https://console.cloud.google.com/ and select a project you own.
2. Enable **Google Sheets API** for that project.
3. Configure the **Google Auth Platform / OAuth consent screen**.
4. Keep the app in **Testing** and add your own Google address as a test user.
5. Create an **Android** OAuth client using package:
   `ma.payday.payday_mobile`.
6. Provide the **actual SHA-1 fingerprint of the key signing the APK**.
   For local development on Windows, run:
   `keytool -list -v -alias androiddebugkey -keystore "%USERPROFILE%\\.android\\debug.keystore" -storepass android -keypass android`
   (when the default Android debug keystore exists).
7. Create a **Web application** OAuth client in the **same Google Cloud project**.
8. Use the public **Web client ID**, not a client secret, when launching Flutter.
9. Never upload a keystore, signing password, private key, or OAuth client secret to this repository.

The app expects the Web client ID through a compile-time Dart define:

```powershell
flutter create --platforms=android --org=ma.payday --project-name=payday_mobile .
python tool/harden_android.py
flutter pub get
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

The OAuth client ID itself is not secret; only share it if comfortable doing so.
**Never share your Google password or OAuth client secret.**

## Test steps

1. Sign into the Android app using the account that can edit the DEMO sheet.
2. Confirm categories and transactions appear from `Settings` and `Record`.
3. Add one small fictional expense to a **separate copy of the DEMO**.
   Do not test on the original sheet; this source currently points to the
   original demo ID, so make a deliberate test-only ID override in a review
   branch before attempting a write test.
4. Confirm a single row is saved in `Record`, with its `Expense` formula
   untouched.
5. Disconnect the internet during a save, reconnect, and use Verify & Sync.
6. Confirm duplicate attempts do not create a second row.
7. Confirm original-date attribution for expenses entered late.

## Limitations before real-world use

- The Google Sheets OAuth scope requested today is broader than file-scoped.
- No server-side compare-and-swap locking, so **do not use multiple phones concurrently**.
- No completed biometric lock or penetration testing yet.
- GitHub Actions builds an APK for compile testing, not a signed production
  install with a valid personal Google OAuth configuration.

Provider setup reference: https://pub.dev/packages/google_sign_in_android
