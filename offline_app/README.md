# Payday Local — Android (offline-only)

This is a **separate Android application** with application ID `ma.payday.payday_local`. It does not alter or replace the existing Google Sheets app (`ma.payday.payday_mobile`).

## Features copied from the Payday spreadsheet logic

- **Home:** selected calendar month/year, income, spending, savings moved, unpaid bills, remaining safe cash and a purchase decision helper.
- **Records:** local add/edit/delete of Expense, Income, Savings out, Savings in. Expense entries can include a unique Bill ID; dates drive reporting.
- **Monthly budgets:** unique budget per month/year/category; income plan and savings goal; essentials and flexible categories.
- **Bills:** due date, bill code, expense-category link, paid-to-date and partial outstanding balance computed from Expense rows.
- **Savings:** savings pool = opening savings + savings transfers out - savings transfers in + confirmed month-close extras. Goal allocations **do not** increase the savings pool.
- **Month close:** checks for transactions and balance, amount of extra savings, and refusal to close future/current months.
- **Reserves:** future occasional-expense targets with **dated actual transfers** into/out of each pot, a progress bar, a movement history, remaining target, and a calculated suggested contribution for next month. Contributions reduce this month's spendable cash without increasing expense totals.
- **Year overview:** monthly income, expense, and recorded transfers.
- **Backup:** JSON export through Android's Share sheet; explicit restore replaces the local database atomically.

## Using the reserve ledger (v1.1.0)

1. Open **More → Occasional expenses** and create a reserve with a target and due date.
2. Tap **Add money**, enter the actual amount and date, and save it. Payday records a dated reserve transfer and subtracts it from the selected month's available cash.
3. The reserve card immediately updates **Put aside**, **Still needed**, its progress indicator, and **Suggested next month**.
4. **Take out** returns reserved money to spendable cash and records the withdrawal.
5. **View transfer history** shows each move. The reserve movement is **not** an expense or a savings-goal allocation. When you actually spend the saved money, first take it out of the reserve and then record the purchase as an ordinary expense.

A reserve's **opening funded** amount means money already set aside before Payday tracked it. It is an opening balance and **is not newly deducted** from monthly spendable cash. Only transfers recorded using **Add money** reduce monthly available cash. Existing reserve and transaction records are retained by the SQLite schema v1 → v2 migration.

Local backups exported by v1.1.0 use schema v2 and include reserve transfers; importing an older schema-v1 backup is supported and creates an empty reserve transfer history.

## Storage and privacy

All finance data is saved to a private on-device SQLite database. No Google Sign-In, Sheets API, analytics, network client, or Internet permission is required by the release APK. App-level SQLCipher encryption, PIN/biometric gate, multi-device sync and automated cloud backups are **not** included. Android system backup is disabled in the generated release manifest.

**Important:** Local data is lost if Android app data is cleared, or the app is uninstalled, unless you first export a backup. Treat the JSON backup as sensitive information and store it securely. Do not share it publicly.

## Install test APK

Visit the [GitHub Actions runs](https://github.com/flymoa/payday-android/actions/workflows/payday-offline-ci.yml?query=branch%3Apayday-local-offline-v1), open the latest successful run, download `payday-local-offline-v1-apk`, unzip and install `app-release.apk`. Use your own judgement about installing test applications.

This is a **first functional build**, not a certified production financial application. No real data has been imported. The app starts with the categories and three example savings-goal definitions, but **no financial transactions**.

For future versions, use a permanent private signing keystore rather than relying on CI's development-key cache. Export a backup first before uninstalling or changing signing identities.

## Source

`offline_app/` contains an independent Flutter app. To build on your own computer:

```bash
cd offline_app
flutter create --platforms android --org ma.payday --project-name payday_local .
flutter pub get
flutter test
flutter build apk --release
```

Flutter's default generated Android app module uses a development signing configuration. Configure production signing before publishing.
