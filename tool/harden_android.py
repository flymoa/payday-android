"""Harden generated Android files; run after flutter create."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
manifest = root / "android/app/src/main/AndroidManifest.xml"
if not manifest.exists():
    raise SystemExit("Run flutter create --platforms=android first")
source = manifest.read_text(encoding="utf8")
if "android.permission.INTERNET" not in source:
    source = source.replace("<application",
        '<uses-permission android:name="android.permission.INTERNET" />\n    <application', 1)
match = re.search(r"<application\b[^>]*>", source, flags=re.S)
if not match:
    raise SystemExit("Android application tag missing")
tag = match.group(0)
for name, value in {
    "android:allowBackup": "false",
    "android:usesCleartextTraffic": "false",
    "android:dataExtractionRules": "@xml/data_extraction_rules",
}.items():
    if re.search(name + r'="[^"]*"', tag):
        tag = re.sub(name + r'="[^"]*"', name + '="' + value + '"', tag)
    else:
        tag = tag[:-1] + ' ' + name + '="' + value + '">'
source = source[:match.start()] + tag + source[match.end():]
manifest.write_text(source, encoding="utf8")

for gradle in [root / "android/app/build.gradle.kts",
               root / "android/app/build.gradle"]:
    if not gradle.exists():
        continue
    content = gradle.read_text(encoding="utf8")
    if "ma.payday.payday_mobile" not in content:
        raise SystemExit("Unexpected Android package ID: " + str(gradle))
    content = content.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
    content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 24")
    gradle.write_text(content, encoding="utf8")

activity = root / "android/app/src/main/kotlin/ma/payday/payday_mobile/MainActivity.kt"
activity.parent.mkdir(parents=True, exist_ok=True)
activity.write_text("""package ma.payday.payday_mobile
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
""", encoding="utf8")

rules = root / "android/app/src/main/res/xml/data_extraction_rules.xml"
rules.parent.mkdir(parents=True, exist_ok=True)
rules.write_text("""<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules xmlns:android="http://schemas.android.com/apk/res/android">
  <cloud-backup><exclude domain="root" path="." /></cloud-backup>
  <device-transfer><exclude domain="root" path="." /></device-transfer>
</data-extraction-rules>
""", encoding="utf8")
print("Android backup, screenshots and cleartext traffic protections applied.")
