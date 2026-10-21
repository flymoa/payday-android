"""Apply the approved icon after flutter create; no external image dependencies."""
import base64
import re
from pathlib import Path
source = Path('lib/brand.dart').read_text()
match = re.search(r"const paydayIconBase64 = '([^']+)';", source)
if match is None:
    raise RuntimeError('Approved icon missing')
icon = base64.b64decode(match[1], validate=True)
for density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']:
    target = Path(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(icon)
