# PAYDAY settings

Home's logo opens a partial-width left settings drawer. More > Settings opens
the same drawer. It contains Light/Dark/System appearance, currency, money
settings and backups. A close control, scrim tap, swipe and Android Back close it.
Opening branding is always enabled; legacy opening/reduce-motion preferences
are ignored and removed on the next preferences save. Android accessibility
settings still control reduced motion. There are no app animation toggles.

Stage 2: one base currency, MAD, EUR, GBP or USD (US dollar). Defaults and older
backups without a currency stay MAD. Currency and theme persist atomically in
the existing settings table, travel in backups and reload before first frame.
All financial screens and entry labels use the selected currency. Calculations
continue in integer minor units; no rates, conversion, network or additional
permissions are introduced. Every currency change requires a plain-language
confirmation showing that 100 old units become 100 new units. Cancel and save
failure preserve both active and stored values. Financial records are untouched.

Later stages cover translated languages and layouts, app locking, storage and
backup encryption, local reminders and About/help. Keep permission requests
contextual and preserve PAYDAY's visual identity.
