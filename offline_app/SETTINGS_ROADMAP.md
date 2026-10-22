# PAYDAY settings

Stage 1 adds More > Settings, grouped preference rows, Light/Dark/System
appearance, a cold-launch branding switch and Reduce motion. Defaults remain
Light, branding enabled and device accessibility preferences respected.
Preferences are written atomically to the existing local settings table and
loaded before the first Flutter frame. Financial records are not changed.

The Home slogan is small, bold and on one line; the date and logo remain.

Next currency choices: MAD, EUR, GBP and USD. USD means US dollar; it is not
a separate fifth currency. Preserve existing MAD records. A currency selector
must not silently relabel stored amounts or imply live exchange conversion.
Currency support is a later stage, not an inactive control in Stage 1.

Later stages cover translated languages and layouts, app locking, storage and
backup encryption, local reminders and About/help. Keep permission requests
contextual, show current values and preserve PAYDAY's visual identity.
