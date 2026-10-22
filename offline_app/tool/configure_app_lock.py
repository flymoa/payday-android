"""Configure local_auth and Android's secure window after flutter create.
Run from offline_app. Does not read, write, or generate signing keys.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET


def configure(root=Path('.')):
    android = root / 'android/app/src/main'
    candidates = list((android / 'kotlin').rglob('MainActivity.kt'))
    if len(candidates) != 1:
        raise RuntimeError('Expected exactly one Kotlin MainActivity')
    target = candidates[0]
    old = target.read_text()
    package = re.search(r'(?m)^package\s+([\w.]+)', old)
    if package is None:
        raise RuntimeError('MainActivity package missing')
    body = re.sub(r'(?m)^(package|import)\s+.*$', '', old).strip()
    if 'PAYDAY_DEVICE_PRIVACY' not in old and not re.fullmatch(
        r'class\s+MainActivity\s*:\s*FlutterActivity\s*\(\s*\)\s*(?:\{\s*\})?', body
    ):
        raise RuntimeError('Custom MainActivity found; refusing to overwrite native changes')
    target.write_text('''package __PACKAGE__

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager

// PAYDAY_DEVICE_PRIVACY: native credentials stay inside Android/local_auth.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ma.payday/privacy")
            .setMethodCallHandler { call, result ->
                if (call.method == "setPrivacy") {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (enabled) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
'''.replace('__PACKAGE__', package.group(1)))
    namespace = 'http://schemas.android.com/apk/res/android'
    ET.register_namespace('android', namespace)
    manifest = android / 'AndroidManifest.xml'
    tree = ET.parse(manifest)
    if not any(p.get(f'{{{namespace}}}name') == 'android.permission.USE_BIOMETRIC'
               for p in tree.getroot().findall('uses-permission')):
        tree.getroot().insert(0, ET.Element('uses-permission', {
            f'{{{namespace}}}name': 'android.permission.USE_BIOMETRIC'}))
    tree.write(manifest, encoding='utf-8', xml_declaration=True)
    for style_file in (android / 'res').glob('values*/styles.xml'):
        tree = ET.parse(style_file)
        for style in tree.getroot().findall('style'):
            if style.get('name') in ('LaunchTheme', 'NormalTheme'):
                style.set('parent', 'Theme.AppCompat.DayNight.NoActionBar')
        tree.write(style_file, encoding='utf-8', xml_declaration=True)
    gradle = root / 'android/app/build.gradle.kts'
    source = gradle.read_text()
    source = source.replace('minSdk = flutter.minSdkVersion',
                            'minSdk = maxOf(flutter.minSdkVersion, 24)')
    gradle.write_text(source)


if __name__ == '__main__':
    configure()
