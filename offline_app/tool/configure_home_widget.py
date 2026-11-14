"""Add the optional Payday home-screen widget after flutter create.
Run from offline_app, after configure_app_lock.py. Repeatable.
The widget only shows text Flutter sends; nothing is read from the database natively.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

MARKER = 'PAYDAY_HOME_WIDGET'
NS = 'http://schemas.android.com/apk/res/android'


def configure(root=Path('.')):
    main = root / 'android/app/src/main'
    activities = list((main / 'kotlin').rglob('MainActivity.kt'))
    if len(activities) != 1:
        raise RuntimeError('Expected exactly one Kotlin MainActivity')
    activity = activities[0]
    source = activity.read_text()
    package = re.search(r'(?m)^package\s+([\w.]+)', source).group(1)
    if 'PAYDAY_DEVICE_PRIVACY' not in source:
        raise RuntimeError('Run configure_app_lock.py first')
    if MARKER not in source:
        anchor = '        super.configureFlutterEngine(flutterEngine)\n'
        if source.count(anchor) != 1:
            raise RuntimeError('MainActivity layout changed; refusing to edit')
        source = source.replace(anchor, anchor + '''        // PAYDAY_HOME_WIDGET: Flutter sends ready-made, user-approved text only.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ma.payday/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "update") {
                    getSharedPreferences("payday_widget", MODE_PRIVATE).edit()
                        .putString("title", call.argument<String>("title") ?: "Payday")
                        .putString("body", call.argument<String>("body") ?: "")
                        .apply()
                    PaydayWidget.refreshAll(this)
                    result.success(null)
                } else if (call.method == "takeAction") {
                    result.success(PaydayWidget.takeAction())
                } else {
                    result.notImplemented()
                }
            }
''')
        activity.write_text(source)
    source = activity.read_text()
    if 'PAYDAY_WIDGET_ACTION' not in source:
        header = 'class MainActivity : FlutterFragmentActivity() {\n'
        if source.count(header) != 1:
            raise RuntimeError('MainActivity class header changed; refusing to edit')
        source = source.replace(header, header + '''    // PAYDAY_WIDGET_ACTION: the widget's + button asks Payday to open a new expense.
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        PaydayWidget.capture(intent)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        PaydayWidget.capture(intent)
    }

''')
        activity.write_text(source)
    (activity.parent / 'PaydayWidget.kt').write_text('''package __PACKAGE__

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class PaydayWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) render(context, manager, id)
    }

    companion object {
        fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences("payday_widget", Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.payday_widget)
            views.setTextViewText(R.id.payday_widget_title, prefs.getString("title", "Payday"))
            views.setTextViewText(R.id.payday_widget_body, prefs.getString("body", "Tap to open"))
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
                val pending = PendingIntent.getActivity(context, 0, launch,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                views.setOnClickPendingIntent(R.id.payday_widget_info, pending)
                val add = Intent(launch).putExtra(ACTION_EXTRA, ADD_EXPENSE)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                val addPending = PendingIntent.getActivity(context, 1, add,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                views.setOnClickPendingIntent(R.id.payday_widget_add, addPending)
            }
            manager.updateAppWidget(id, views)
        }

        const val ACTION_EXTRA = "payday_action"
        const val ADD_EXPENSE = "add_expense"
        @Volatile private var pendingAction: String? = null

        fun capture(intent: Intent?) {
            val action = intent?.getStringExtra(ACTION_EXTRA) ?: return
            pendingAction = action
            intent.removeExtra(ACTION_EXTRA)
        }

        fun takeAction(): String? {
            val action = pendingAction
            pendingAction = null
            return action
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PaydayWidget::class.java))
            for (id in ids) render(context, manager, id)
        }
    }
}
'''.replace('__PACKAGE__', package))
    res = main / 'res'
    for folder in ('layout', 'xml', 'drawable'):
        (res / folder).mkdir(parents=True, exist_ok=True)
    (res / 'drawable/payday_widget_background.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#FF12261F" />
    <corners android:radius="20dp" />
</shape>
''')
    (res / 'drawable/payday_widget_add_background.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="#FFF4B740" />
</shape>
''')
    (res / 'layout/payday_widget.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/payday_widget_root"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="horizontal" android:gravity="center_vertical"
    android:paddingStart="14dp" android:paddingEnd="10dp" android:paddingTop="10dp" android:paddingBottom="10dp"
    android:background="@drawable/payday_widget_background">
    <LinearLayout android:id="@+id/payday_widget_info"
        android:layout_width="0dp" android:layout_height="match_parent" android:layout_weight="1"
        android:orientation="vertical" android:gravity="center">
        <TextView android:id="@+id/payday_widget_title"
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:gravity="center" android:textAlignment="center"
            android:text="Payday" android:textColor="#FFF4B740" android:textSize="13sp" android:textStyle="bold" />
        <TextView android:id="@+id/payday_widget_body"
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:gravity="center" android:textAlignment="center"
            android:text="Tap to open" android:textColor="#FFFFFFFF" android:textSize="18sp" android:textStyle="bold"
            android:maxLines="2" android:ellipsize="end" />
    </LinearLayout>
    <TextView android:id="@+id/payday_widget_add"
        android:layout_width="40dp" android:layout_height="40dp" android:layout_marginStart="8dp"
        android:gravity="center" android:text="+" android:textColor="#FF12261F" android:textSize="24sp"
        android:textStyle="bold" android:contentDescription="Add expense"
        android:background="@drawable/payday_widget_add_background" />
</LinearLayout>
''')

    (res / 'xml/payday_widget_info.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp" android:minHeight="70dp"
    android:targetCellWidth="3" android:targetCellHeight="1"
    android:updatePeriodMillis="0" android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" android:initialLayout="@layout/payday_widget"
    android:previewLayout="@layout/payday_widget" />
''')
    ET.register_namespace('android', NS)
    manifest = main / 'AndroidManifest.xml'
    tree = ET.parse(manifest)
    app = tree.getroot().find('application')
    if not any(r.get(f'{{{NS}}}name') == '.PaydayWidget' for r in app.findall('receiver')):
        receiver = ET.SubElement(app, 'receiver', {f'{{{NS}}}name': '.PaydayWidget',
            f'{{{NS}}}exported': 'true', f'{{{NS}}}label': 'Payday'})
        intent = ET.SubElement(receiver, 'intent-filter')
        ET.SubElement(intent, 'action', {f'{{{NS}}}name': 'android.appwidget.action.APPWIDGET_UPDATE'})
        ET.SubElement(receiver, 'meta-data', {f'{{{NS}}}name': 'android.appwidget.provider',
            f'{{{NS}}}resource': '@xml/payday_widget_info'})
    tree.write(manifest, encoding='utf-8', xml_declaration=True)


if __name__ == '__main__':
    configure()
