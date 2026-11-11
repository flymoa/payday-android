"""Keep SQLCipher's native bridge classes in release builds (R8 shrinking)."""
from pathlib import Path

RULES = """# PAYDAY_SQLCIPHER: encrypted database (sqflite_sqlcipher)
-keep class net.sqlcipher.** { *; }
-keep class net.zetetic.** { *; }
"""


def configure(root=Path('.')):
    rules = root / 'android/app/proguard-rules.pro'
    text = rules.read_text() if rules.exists() else ''
    if 'PAYDAY_SQLCIPHER' not in text:
        rules.write_text(text + ('\n' if text and not text.endswith('\n') else '') + RULES)


if __name__ == '__main__':
    configure()
