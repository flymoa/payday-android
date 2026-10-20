# Payday Android — private DEMO integration

Security-first Flutter Android app connected to the **DEMO — Payday Tracker — Fictional Data** Google Sheet, never the outdated official tracker.

### Implemented in GitHub

- Google Sign-In (requires your own OAuth credentials before device login).
- Read expense categories from DEMO `Settings`.
- Read month-filtered income and expenses from `Record`.
- Add expenses to a verified empty `Record` row while keeping the `Expense` formula in column B.
- Unique transaction marker in `Record!F` with readback confirmation to reduce duplicate retry risk.
- Encrypted local queue and retry while app is open; pending entries survive disconnect.
- Android hardening script, unit tests, and a GitHub Actions Flutter workflow.

### Development status

**Source uploaded; Android CI configured. Build result not yet verified.**
A debug APK compiled by CI will **not** have Google OAuth configured and is **not** a production-ready finance app. No real phone-to-Sheets test has passed yet.

### Data source

- Original DEMO: `1lu6JabfKowbZhHXrGD9rJeQdbpXNc9_YnTPucSr9_Yg`
- Separate sync validation copy: `1gpWUxFX4PI3fiImiiO_oz-nsLrx0ixHmQyx78MhcjmU`
- Use a developer-supplied build-time `PAYDAY_TEST_SHEET_ID` to direct testing exclusively to the separate copy.

### Required setup

See [Google OAuth setup](docs/GOOGLE_OAUTH_SETUP.md) for your Android package ID, SHA-1 certificate, Google Cloud project, Web client ID, and first test commands.

### Outstanding security work

Google Sheets OAuth scope is currently broader than one file; production requires a file-scoped authorization design. **Do not synchronize from multiple phones** until transactional locking is implemented. Biometric re-lock, security testing, an authenticated release build, and runtime Android verification remain outstanding. Do not store sensitive real financial records in this test build.

### CI

See [Actions](../../actions). Jobs generate the Android platform, apply hardening, analyze code, run tests, and attempt a debug build. Test reports and build artifacts must be verified before installing.
