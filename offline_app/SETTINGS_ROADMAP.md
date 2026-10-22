# PAYDAY settings

Home's P logo is the only settings entry. It opens a partial-width left drawer.
More contains financial tools only. Opening by an edge swipe is disabled; the
close control, scrim tap, closing swipe and Android Back still close the drawer.
Opening branding is always enabled; Android reduced-motion settings are respected.
There are no app animation toggles.

Appearance and base currency (MAD, EUR, GBP, USD) persist in the existing local
settings table. Currency changes require explicit confirmation that numbers are
not converted. Records and financial calculations continue in integer minor units.

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

App lock is an access gate, not database or backup encryption. Remaining stages:
language translations and layout direction, encrypted storage/backups, local
reminders and About/help. Keep permission requests contextual and preserve the
PAYDAY identity. CI uses the permanent signing certificate for in-place updates.

Native setup references:
https://pub.dev/packages/local_auth
https://pub.dev/packages/local_auth_android
