import tempfile
import unittest
from pathlib import Path
import xml.etree.ElementTree as ET
from configure_app_lock import configure


class AndroidSetupTest(unittest.TestCase):
    def test_native_configuration_is_repeatable_and_preserves_identity_and_brand(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            main = root / 'android/app/src/main'
            activity = main / 'kotlin/ma/payday/payday_local/MainActivity.kt'
            activity.parent.mkdir(parents=True)
            activity.write_text('package ma.payday.payday_local\nimport io.flutter.embedding.android.FlutterActivity\nclass MainActivity: FlutterActivity()\n')
            manifest = main / 'AndroidManifest.xml'
            manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application android:label="payday_local" android:allowBackup="false"><activity android:name=".MainActivity"/></application></manifest>')
            styles = main / 'res/values/styles.xml'
            styles.parent.mkdir(parents=True)
            styles.write_text('<resources><style name="LaunchTheme" parent="old"><item name="android:windowSplashScreenAnimatedIcon">@drawable/launch_empty</item></style></resources>')
            gradle = root / 'android/app/build.gradle.kts'
            gradle.write_text('minSdk = flutter.minSdkVersion\nsigningConfig = signingConfigs.getByName("paydayRelease")\napplicationId = "ma.payday.payday_local"')
            configure(root)
            first = [p.read_bytes() for p in (activity, manifest, styles, gradle)]
            configure(root)
            self.assertEqual(first, [p.read_bytes() for p in (activity, manifest, styles, gradle)])
            self.assertIn('FlutterFragmentActivity', activity.read_text())
            self.assertIn('window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)', activity.read_text())
            self.assertIn('window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)', activity.read_text())
            self.assertIn('super.configureFlutterEngine', activity.read_text())
            self.assertIn('paydayRelease', gradle.read_text())
            self.assertIn('ma.payday.payday_local', gradle.read_text())
            self.assertIn('maxOf(flutter.minSdkVersion, 24)', gradle.read_text())
            xml = ET.parse(manifest)
            name = '{http://schemas.android.com/apk/res/android}name'
            self.assertEqual([e.get(name) for e in xml.getroot().findall('uses-permission')], ['android.permission.USE_BIOMETRIC'])
            self.assertEqual(ET.parse(styles).find('style/item').text, '@drawable/launch_empty')
            self.assertIn('android:label="payday_local"', manifest.read_text())
            activity.write_text('package ma.payday.payday_local\nclass MainActivity: FlutterActivity() { fun custom() {} }')
            with self.assertRaisesRegex(RuntimeError, 'Custom MainActivity'):
                configure(root)
            self.assertIn('fun custom()', activity.read_text())


if __name__ == '__main__':
    unittest.main()
