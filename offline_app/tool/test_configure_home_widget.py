import tempfile
import unittest
from pathlib import Path
from configure_home_widget import configure

ACTIVITY = '''package ma.payday.payday_local

// PAYDAY_DEVICE_PRIVACY
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    }
}
'''


class HomeWidgetSetupTest(unittest.TestCase):
    def test_adds_widget_once_and_is_repeatable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            main = root / 'android/app/src/main'
            activity = main / 'kotlin/ma/payday/payday_local/MainActivity.kt'
            activity.parent.mkdir(parents=True)
            activity.write_text(ACTIVITY)
            (main / 'AndroidManifest.xml').write_text(
                '<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application android:label="Payday"></application></manifest>')
            configure(root)
            configure(root)
            source = activity.read_text()
            self.assertEqual(source.count('PAYDAY_HOME_WIDGET'), 1)
            self.assertIn('package ma.payday.payday_local', (activity.parent / 'PaydayWidget.kt').read_text())
            manifest = (main / 'AndroidManifest.xml').read_text()
            self.assertEqual(manifest.count('.PaydayWidget'), 1)
            self.assertNotIn('INTERNET', manifest)
            self.assertTrue((main / 'res/xml/payday_widget_info.xml').exists())
            layout = (main / 'res/layout/payday_widget.xml').read_text()
            self.assertEqual(layout.count('android:textAlignment="center"'), 2)

    def test_refuses_before_app_lock_setup(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            activity = root / 'android/app/src/main/kotlin/x/MainActivity.kt'
            activity.parent.mkdir(parents=True)
            activity.write_text('package x\nclass MainActivity: FlutterActivity()\n')
            with self.assertRaises(RuntimeError):
                configure(root)


if __name__ == '__main__':
    unittest.main()
