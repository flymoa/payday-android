from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
import xml.etree.ElementTree as ET
from configure_notifications import configure,ANDROID,PREFIX

class ConfigureNotificationsTest(unittest.TestCase):
    def test_preserves_security_and_signing_and_is_idempotent(self):
        with TemporaryDirectory() as tmp:
            root=Path(tmp);main=root/'android/app/src/main';main.mkdir(parents=True)
            manifest=main/'AndroidManifest.xml'
            manifest.write_text(f'<manifest xmlns:android="{ANDROID}"><uses-permission android:name="android.permission.USE_BIOMETRIC"/><application android:allowBackup="false"><activity android:name=".MainActivity"/></application></manifest>')
            gradle=root/'android/app/build.gradle.kts'
            gradle.write_text('android {\n compileSdk = flutter.compileSdkVersion\n compileOptions { sourceCompatibility = JavaVersion.VERSION_17 }\n signingConfig = signingConfigs.getByName("paydayRelease")\n}')
            configure(root);first=manifest.read_bytes();gradle_first=gradle.read_text();configure(root)
            self.assertEqual(first,manifest.read_bytes());self.assertEqual(gradle_first,gradle.read_text())
            doc=ET.parse(manifest).getroot();perms={p.get(f'{{{ANDROID}}}name') for p in doc.findall('uses-permission')}
            self.assertEqual(perms,{'android.permission.USE_BIOMETRIC','android.permission.POST_NOTIFICATIONS','android.permission.RECEIVE_BOOT_COMPLETED'})
            self.assertEqual(doc.find('application').get(f'{{{ANDROID}}}allowBackup'),'false')
            receivers=doc.find('application').findall('receiver');self.assertEqual(len(receivers),2)
            self.assertTrue(all(r.get(f'{{{ANDROID}}}exported')=='false' for r in receivers))
            self.assertIn('paydayRelease',gradle_first);self.assertIn('isCoreLibraryDesugaringEnabled = true',gradle_first)
            self.assertTrue((main/'res/drawable/payday_notification.xml').is_file())
            ET.parse(main/'res/drawable/payday_notification.xml');ET.parse(main/'res/raw/payday_keep.xml')

if __name__=='__main__':unittest.main()
