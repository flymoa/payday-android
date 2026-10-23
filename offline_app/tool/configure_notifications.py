"""Configure optional, inexact local notifications after flutter create.
Does not change package identity, signing, app-lock activity, or privacy flags.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

ANDROID='http://schemas.android.com/apk/res/android'
PREFIX='com.dexterous.flutterlocalnotifications.'

def configure(root=Path('.')):
    main=root/'android/app/src/main'
    manifest=main/'AndroidManifest.xml'
    ET.register_namespace('android',ANDROID)
    tree=ET.parse(manifest)
    doc=tree.getroot()
    app=doc.find('application')
    if app is None: raise RuntimeError('Android application is missing')
    for name in ['android.permission.POST_NOTIFICATIONS','android.permission.RECEIVE_BOOT_COMPLETED']:
        if not any(p.get(f'{{{ANDROID}}}name')==name for p in doc.findall('uses-permission')):
            doc.insert(0,ET.Element('uses-permission',{f'{{{ANDROID}}}name':name}))
    for cls in ['ScheduledNotificationReceiver','ScheduledNotificationBootReceiver']:
        name=PREFIX+cls
        receiver=next((r for r in app.findall('receiver') if r.get(f'{{{ANDROID}}}name')==name),None)
        if receiver is None: receiver=ET.SubElement(app,'receiver',{f'{{{ANDROID}}}name':name})
        receiver.set(f'{{{ANDROID}}}exported','false')
        if cls.endswith('BootReceiver'):
            for child in list(receiver): receiver.remove(child)
            intent=ET.SubElement(receiver,'intent-filter')
            for action in ['android.intent.action.BOOT_COMPLETED','android.intent.action.MY_PACKAGE_REPLACED','android.intent.action.QUICKBOOT_POWERON','com.htc.intent.action.QUICKBOOT_POWERON']:
                ET.SubElement(intent,'action',{f'{{{ANDROID}}}name':action})
    tree.write(manifest,encoding='utf-8',xml_declaration=True)
    gradle=root/'android/app/build.gradle.kts'
    text=gradle.read_text()
    marker='// PAYDAY_LOCAL_NOTIFICATIONS'
    if marker not in text:
        if text.count('compileOptions {')!=1: raise RuntimeError('Unexpected compile options template')
        text=text.replace('compileOptions {','compileOptions {\n        isCoreLibraryDesugaringEnabled = true')
        text=text.replace('JavaVersion.VERSION_11','JavaVersion.VERSION_17')
        text=text.replace('compileSdk = flutter.compileSdkVersion','compileSdk = maxOf(flutter.compileSdkVersion, 36)')
        text+='\n'+marker+'\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    gradle.write_text(text)
    res=main/'res'
    (res/'drawable').mkdir(parents=True,exist_ok=True)
    (res/'drawable/payday_notification.xml').write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFFFF" android:fillType="evenOdd" android:pathData="M6,3H14C19,3 21,6 21,9C21,12 19,15 14,15H10V21H6Z M10,7V11H14C16,11 17,10 17,9C17,8 16,7 14,7Z"/>
</vector>''')
    (res/'raw').mkdir(parents=True,exist_ok=True)
    (res/'raw/payday_keep.xml').write_text('<resources xmlns:tools="http://schemas.android.com/tools" tools:keep="@drawable/payday_notification"/>')

if __name__=='__main__': configure()
