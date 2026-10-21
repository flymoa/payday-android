# First Android connection: Google OAuth

The project uses only the **Payday fictional-data DEMO spreadsheet**.
The GitHub Actions APK is a **compile-only debug artifact** until OAuth is configured.

## Build an OAuth-enabled test APK entirely through GitHub

No local Flutter installation is required for this test.

1. In Google Cloud → **Google Auth Platform → Clients**, confirm you have
   *both* **Android** (package `ma.payday.payday_mobile`, matching GitHub SHA-1)
   and **Web application** clients in the **same project**.
2. Confirm the project's **Google Sheets API** is enabled and your Google
   account is added to **Audience → Test users** when in Testing mode.
3. Open https://github.com/flymoa/payday-android/actions/workflows/android-ci.yml
4. Click **Run workflow**.
5. Enter the **Web application Client ID** into the `web_client_id` field.
   It normally ends with `.apps.googleusercontent.com`. Never enter the
   client **secret**, password, or Android client ID.
6. Start the workflow. The debug APK build is automatically pointed at the
   isolated DEMO validation copy `1gpWUxFX4PI3fiImiiO_oz-nsLrx0ixHmQyx78MhcjmU`.
7. Check for a **passing** Flutter test/build and the
   `payday-demo-debug-test-copy` artifact.

If the `web_client_id` field is left empty, the project can compile for
diagnostics, but Google Sign-In remains unconfigured. A repository Actions
variable named `PAYDAY_GOOGLE_WEB_CLIENT_ID` is also supported as an
alternative to entering the ID for every manual build.

The OAuth Client ID is a public identifier embedded in the APK; the OAuth
Client **secret** must never be copied into GitHub or the app.

## Easiest SHA-1 method: GitHub Actions (no Java installation)

For the APK built by our GitHub workflow, **use the fingerprint printed by
GitHub**, not the fingerprint from a different computer:

1. Open https://github.com/flymoa/payday-android/actions
2. Open the newest **Android validation (DEMO only)** workflow run.
   If no run appears, choose the workflow and click **Run workflow**.
3. On the run's **Summary** page, find **Payday Android — debug APK SHA-1**.
4. Copy only the hexadecimal fingerprint, for example
   `AA:BB:CC:...:FF` (your actual value will be different).
5. In https://console.cloud.google.com/auth/clients create an **Android**
   OAuth client. Use package `ma.payday.payday_mobile` and paste that SHA-1.
6. Create a **Web application** OAuth client in the same Google Cloud project
   and use its client ID when building Payday.

**Important:** GitHub caches the development signing keystore, but the cache
can be evicted. The SHA-1 may change if a new key has to be generated. A
durable private signing key will be needed before release. Never post or
commit keystore files or their passwords.

## Google Cloud configuration (one-time)

1. Visit https://console.cloud.google.com/ and select a project you own.
2. Enable **Google Sheets API** for that project.
3. Configure the **Google Auth Platform / OAuth consent screen**.
4. Keep the app in **Testing** and add your own Google address as a test user.
5. Create an **Android** OAuth client using package:
   `ma.payday.payday_mobile`.
6. Provide the **actual SHA-1 fingerprint of the key signing the APK**.
   For local development on Windows, run:
   `keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\\.android\\debug.keystore" -storepass android -keypass android`
   (when the default Android debug keystore exists).
7. Create a **Web application** OAuth client in the **same Google Cloud project**.
8. Use the public **Web client ID**, not a client secret, when launching Flutter.
9. Never upload a keystore, signing password, private key, or OAuth client secret to this repository.

The app expects the Web client ID through a compile-time Dart define:

```powershell
flutter create --platforms=android --org=ma.payday --project-name=payday_mobile .
python tool/harden_android.py
flutter pub get
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com --dart-define=PAYDAY_TEST_SHEET_ID=1gpWUxFX4PI3fiImiiO_oz-nsLrx0ixHmQyx78MhcjmU
```

The OAuth client ID itself is not secret; only share it if comfortable doing so.
**Never share your Google password or OAuth client secret.**

## Test steps

1. Sign into the Android app using the account that can edit the DEMO sheet.
2. Confirm categories and transactions appear from `Settings` and `Record`.
3. Use the build-time `PAYDAY_TEST_SHEET_ID` override shown above to
   connect only to our separate validation copy. Record one tiny fictional
   expense in that copy; the original DEMO remains untouched.
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

Build-time note: the `PAYDAY_TEST_SHEET_ID` switch is supplied by the
developer before compilation, never accepted as a URL from the Android
user. Production builds must default to the original fictional-data DEMO
until a safe migration plan is approved.
