# Payday Android

Private development repository for the **Payday Android** personal-finance application.

## Data source

The integration is based **only** on the existing Google Sheets **DEMO — Payday Tracker — Fictional Data**. The outdated official tracker is **not** a permitted target.

- Spreadsheet ID: `1lu6JabfKowbZhHXrGD9rJeQdbpXNc9_YnTPucSr9_Yg`
- Transaction input: `Record` (row 6 onward)
- Computed transaction history: `Transactions` (read only)
- Categories: `Settings`
- Monthly budget history: `Budget history`

## Priorities

1. Secure Google authentication and explicit consent.
2. Safe sheet synchronization: protect formulas, verify write-back, prevent duplicates and recover from network failures.
3. Offline encrypted pending-expense queue.
4. Test on a separate copy of the demo; do not write test transactions into the original demo.
5. Android emulator / device tests and a private signed APK.

## Security rules

- **Private repository**: never commit passwords, tokens, service-account credentials, OAuth secrets, keystores, or personal transaction exports.
- Never store OAuth access tokens in application-managed plaintext.
- Keep Google Sheets writes restricted in application code to the demo spreadsheet.
- Current broad Google Sheets OAuth permissions are **not file-scoped**. Move to a file-scoped authorization flow before handling real finances.
- Do not consider the sync engine production-ready until concurrent writes, interrupted sync, and OAuth failure modes are tested.

## Development status

The repository has been initialized for the project. **Flutter source has not yet been imported into this repository.** Spreadsheet-side integration was verified separately on a test copy; full Android-to-Sheets integration is still unverified.

_Development documentation — 20 October 2026._
