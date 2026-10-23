# PAYDAY settings

Home's P logo is the only settings entry. It opens a partial-width left drawer.
More contains financial tools only. Opening by an edge swipe is disabled; the
close control, scrim tap, closing swipe and Android Back still close the drawer.
Opening branding is always enabled; Android reduced-motion settings are respected.
There are no app animation toggles.

Appearance and base currency (MAD, EUR, GBP, USD) persist in the existing local
settings table. Currency changes require explicit confirmation that numbers are
not converted. Records and financial calculations continue in integer minor units.

Security opens a dedicated screen with one App lock switch. A small information
icon opens the explanation on demand; policy and authentication stay unchanged.

Security stage: optional App lock, off until explicitly enabled. Enabling and
disabling require successful Android device authentication. Fingerprint/face
support and PIN/pattern/password fallback are handled by local_auth 3.0.2 and
Android; PAYDAY never stores or receives those credentials. The branded lock
screen covers the Navigator, including open forms and dialogs, on a cold start
or whenever the enabled app loses the foreground. Authentication cancellation
or error never unlocks it. Android Back is consumed while locked; form state is
preserved for successful unlocking. Secure-window flags block screenshots and
recent-app capture while enabled. Native privacy setup must succeed to unlock.
Startup cannot open records if reading security preferences fails; retry is shown.

App lock is specific to this installation. Backups omit its flag and restore
preserves the current phone's lock policy, ignoring any imported lock flag.
Preferences remain atomic. Authentication or storage failures keep the previous
policy. Existing records, DB version 2 and backup schema 2 are preserved.

About & Help now has version/build details and short, tappable topics for getting
started, budgets/savings, backup restore, privacy and updating. Copy app details
contains only the app name and release metadata. CI checks this metadata against
pubspec.yaml so the displayed version cannot silently drift.

Backup stage: new exports use a versioned AES-256-GCM envelope with a fresh
16-byte salt and 12-byte nonce from Random.secure. PBKDF2-HMAC-SHA256 uses
600,000 iterations and a 256-bit key, on a worker isolate. Fixed version/cipher/
KDF metadata is authenticated; unknown parameters and malformed lengths are
rejected before key derivation. Plaintext is limited to 16 MiB; input files to
24 MiB. Only ciphertext is written to the shared temporary file. Passwords are
not saved; they cannot be recovered. Export requires confirmation of a password
of at least 12 characters and acknowledgement that it has been saved. Passwords
are preserved exactly (including Unicode and whitespace), with a 1024-byte cap.
Restore supports legacy schema 1/2 JSON and never imports until decryption and
replacement confirmation succeed. Existing atomic import and device-local lock
policy remain unchanged. Wrong passwords/tampering leave records untouched.
App lock is an access gate, not database encryption. Remaining stages:
language translations and layout direction, encrypted local storage and local
reminders. Keep permission requests contextual and preserve the
PAYDAY identity. CI uses the permanent signing certificate for in-place updates.

Native setup references:
https://pub.dev/packages/local_auth
https://pub.dev/packages/local_auth_android

Backup implementation references:
https://pub.dev/packages/cryptography
https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html

Local reminders, first release: Settings → Notifications offers an opt-in weekly
backup notification, off by default. Enabling requests POST_NOTIFICATIONS in
context. One stable notification ID prevents duplicates; disabling cancels
pending and displayed reminders. A confirmed export resets its interval. No
reminder date is recorded as a successful backup. The notification contains only
a generic backup prompt, with no amounts, transaction titles, passwords or file
paths. App lock still gates the full app when a notification opens it.

flutter_local_notifications 22.3.2 uses inexactAllowWhileIdle weekly alarms;
Android may delay delivery. No exact-alarm, internet, or full-screen permission
is requested. Boot/package-update receivers restore existing opt-in schedules.
The preference is device-local: excluded from backup export, ignored on import,
and the current installation’s setting is preserved atomically during restore.
Permission/channel blocks are shown on the settings page and can be opened in
Android settings. A test button lets the user check delivery immediately.
Bill-specific reminders remain a later part of the notifications stage.

Setup reference: https://pub.dev/packages/flutter_local_notifications

Bill reminders: opt-in, off by default, with due-date/one-day/three-day timing.
Use timezone 0.11.2 and flutter_timezone 5.1.1 for device IANA time zones. Each
future calendar reminder is at 09:00 local time, with inexactAllowWhileIdle;
no exact-alarm or additional Android permission is introduced. Subtract calendar
days before constructing TZDateTime so DST, Ramadan changes and month/year
boundaries retain 09:00. Past reminder times and overdue bills are not replayed.
The next calendar year is queued, grouping unpaid bills by reminder date (fewer
than 370 bill alarms, within Android's documented alarm limits). Opening or
resuming the app refreshes the horizon and picks up a changed device time zone.
The existing boot/update receivers restore already queued reminders.

The planner uses all linked Expense payments, across months, matching the bill
balance logic. Full/overpayment, bill deletion, due-date edits, repeated bills,
transaction edit/delete/Undo, and backup restore reconcile reminders after the
saved change. Partial payments keep a reminder. One date ID per day prevents
duplicates; unchanged pending payloads are retained. Reconciliation removes only
bill-owned pending/displayed IDs and leaves weekly backup reminders alone. A
read transaction takes the bill/payment snapshot. Sync failures report a reminder
error without rolling back or misreporting a saved financial transaction.

Only a generic message is shown: "You have a bill to review. Open PAYDAY for
details." The scheduler stores date/time-zone metadata, no bill name, amount,
category or transaction details. Opening a notification retains the usual App
lock gate. Notification intent and timing are device-local: exports omit them;
restore ignores imported flags and atomically retains this phone's preferences.
Both fields save in a transaction; failures restore the previous Android plan.
Permission is requested only on explicit opt-in, never on startup or restore.

Icons: a receipt with a saffron bell for bill reminders and a matching clock for
timing, drawn in the existing vector icon system in light and dark themes.

References:
https://pub.dev/documentation/flutter_local_notifications/latest/flutter_local_notifications/FlutterLocalNotificationsPlugin/zonedSchedule.html
https://pub.dev/packages/flutter_timezone
https://pub.dev/packages/timezone
