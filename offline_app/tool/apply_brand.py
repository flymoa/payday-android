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

# Cold launches begin in light mode even when Android itself uses dark mode.
# Flutter can switch to the dark palette after launch through the app's control.
import xml.etree.ElementTree as ET
res = Path('android/app/src/main/res')
background = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><shape android:shape="rectangle"><solid android:color="#FBF6EA" /></shape></item>
</layer-list>
'''
for directory in ['drawable', 'drawable-v21']:
    (res / directory).mkdir(parents=True, exist_ok=True)
    (res / directory / 'launch_background.xml').write_text(background)
# Hide the native launch icon; Flutter owns the only branded opening animation.
# A transparent drawable avoids Android falling back to the launcher P.
(res / 'drawable' / 'launch_empty.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <size android:width="1dp" android:height="1dp" />
    <solid android:color="#00000000" />
</shape>
''')
for target in res.glob('values*/styles.xml'):
    tree = ET.parse(target)
    for style in tree.getroot().findall('style'):
        if style.get('name') not in ['LaunchTheme', 'NormalTheme']:
            continue
        style.set('parent', '@android:style/Theme.Light.NoTitleBar')
        values = {
            'android:windowBackground': '@drawable/launch_background',
            'android:statusBarColor': '#FBF6EA',
            'android:navigationBarColor': '#FBF6EA',
            'android:windowLightStatusBar': 'true',
            'android:windowLightNavigationBar': 'true',
        }
        if style.get('name') == 'LaunchTheme':
            values['android:windowSplashScreenBackground'] = '#FBF6EA'
            values['android:windowSplashScreenAnimatedIcon'] = '@drawable/launch_empty'
            values['android:windowSplashScreenIconBackgroundColor'] = '#00000000'
        for name, value in values.items():
            item = next((item for item in style.findall('item') if item.get('name') == name), None)
            if item is None:
                item = ET.SubElement(style, 'item', {'name': name})
            item.text = value
    tree.write(target, encoding='utf-8', xml_declaration=True)

