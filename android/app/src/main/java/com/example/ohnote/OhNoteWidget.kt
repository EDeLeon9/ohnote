package com.example.ohnote // Your package name

import android.view.View
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.net.Uri
import android.app.PendingIntent
import android.os.Bundle
import android.util.TypedValue
import android.graphics.Color
import kotlin.math.roundToInt
import org.json.JSONObject
import org.json.JSONTokener
import org.json.JSONArray
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

internal const val APP_SCHEME_NAME = "ohnotewidget"
internal const val OPEN_NOTE = "opennote"
internal const val EXTRA_NOTELIST = "com.example.ohnote.EXTRA_NOTELIST"
internal const val EXTRA_ITEM_NOTEID = "com.example.ohnote.EXTRA_ITEM_NOTEID"
internal const val EXTRA_ITEM_TEXTCOLOR = "com.example.ohnote.EXTRA_ITEM_TEXTCOLOR"
internal const val INTENT_OPEN_ACTION = "com.example.ohnote.INTENT_OPEN_ACTION"

/*
 * Implementation of App Widget functionality.
 * App Widget Configuration implemented in [OhNoteWidgetConfigureActivity]
 */
class OhNoteWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, prefs: SharedPreferences) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, prefs)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // Enter relevant functionality for when the user deletes the widget
        super.onDeleted(context, appWidgetIds)
        for (appWidgetId in appWidgetIds) {
            deleteConfigId(context, appWidgetId, HomeWidgetPlugin.getData(context))
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
        super.onDisabled(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Called when the BroadcastReceiver receives an Intent broadcast.
        if (intent.action == INTENT_OPEN_ACTION) {
            val noteId = intent.getIntExtra(EXTRA_ITEM_NOTEID, 0)
            
            //Using an intent directly instead of getting a PendingIntent from HomeWidgetLaunchIntent.getActivity()
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = "es.antonborri.home_widget.action.LAUNCH"  //action string From HomeWidgetLaunchIntent: https://github.com/ABausG/home_widget/blob/main/packages/home_widget/android/src/main/kotlin/es/antonborri/home_widget/HomeWidgetIntent.kt
                data = Uri.parse("$APP_SCHEME_NAME://$OPEN_NOTE?id=$noteId")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            context.startActivity(launchIntent)
        }
        super.onReceive(context, intent)
    }
}

internal fun updateAppWidget(
    context: Context, 
    appWidgetManager: AppWidgetManager, 
    appWidgetId: Int,
    prefs: SharedPreferences
) {
    val widgetValues = getWidgetValues(context, appWidgetId, prefs)

    var rootLayoutId = R.layout.ohnote_widget_root
    var backgroundColor = -1
    var rowTextColor = -1
    if (widgetValues.configItem != null) {
        if (widgetValues.configItem.theme == "Light theme") {
            rootLayoutId = R.layout.ohnote_widget_root_light
            backgroundColor = context.getColor(R.color.widget_background_light)
            rowTextColor = context.getColor(R.color.widget_text_light)
        } else if (widgetValues.configItem.theme == "Dark theme") {
            rootLayoutId = R.layout.ohnote_widget_root_dark
            backgroundColor = context.getColor(R.color.widget_background_dark)
            rowTextColor = context.getColor(R.color.widget_text_dark)
        } else {
            rootLayoutId = getSystemDefaultRootLayoutId(widgetValues.configItem.opacity)
        }
    }

    val listViewIntent = Intent(context, NoteListViewWidgetService::class.java).apply {
        // Add the widget ID to the intent extras.
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        putExtra(EXTRA_NOTELIST, widgetValues.noteListString)
        putExtra(EXTRA_ITEM_TEXTCOLOR, rowTextColor)
        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
    }

    val views = RemoteViews(context.packageName, rootLayoutId).apply {
        setRemoteAdapter(R.id.noteListView, listViewIntent)
        
        if (widgetValues.configItem != null) {
            setTextViewText(R.id.titleTextView, widgetValues.configItem.title)
            if (widgetValues.configItem.opacity == 0) {
                setInt(R.id.widgetRoot, "setBackgroundColor", Color.argb(0, 0, 0, 0))
            } else if (backgroundColor != -1) {
                var alpha = (widgetValues.configItem.opacity / 100.0) * 255.0
                setInt(R.id.widgetRoot, "setBackgroundColor", 
                    Color.argb(alpha.roundToInt(), Color.red(backgroundColor), Color.green(backgroundColor), Color.blue(backgroundColor)))
            }
            if (rowTextColor != -1) {
                setTextColor(R.id.emptyTextView, rowTextColor)
            }
        }

        // The empty view is displayed when the collection has no items.
        if (widgetValues.configId > 0 ) {
            setViewVisibility(R.id.emptyTextView, View.GONE)
        } else {
            if (widgetValues.configId == 0) {
                setTextViewText(R.id.emptyTextView, "The configuration for this widget was removed. Replace this widget with a new one.")
            } else {
                setTextViewText(R.id.emptyTextView, "An error occured while loading the widget configuration data.")
            }
            setEmptyView(R.id.noteListView, R.id.emptyTextView)
            setViewVisibility(R.id.emptyTextView, View.VISIBLE)
        }

        // PendingIntent to open app on widget click
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)

        val buttonPendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("$APP_SCHEME_NAME://$OPEN_NOTE?id=0"))
        setOnClickPendingIntent(R.id.addNoteButton, buttonPendingIntent)

        // This section makes it possible for items to have individualized. It does this by setting up a pending intent template.
        // Individuals items of a collection can't set up their own pending intents. Instead, the collection as a whole sets up a pending
        // intent template, and the individual items set a fillInIntent to create unique behavior on an item-by-item basis.
        val pendingIntentTemplate = Intent(context, OhNoteWidget::class.java).run {
            action = INTENT_OPEN_ACTION
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            PendingIntent.getBroadcast(context, 0, this, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        }
        setPendingIntentTemplate(R.id.noteListView, pendingIntentTemplate)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

//Service added in AndroidManifest.xml
class NoteListViewWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return NoteListViewAdapter(this.applicationContext, intent)
    }
}

class NoteListViewAdapter(val context: Context, val intent: Intent) : RemoteViewsService.RemoteViewsFactory {
    private var data: ArrayList<NoteItem> = arrayListOf()
    private var textColor: Int = -1
        
    override fun onCreate() {
        // In onCreate() you setup any connections / cursors to your data source. Heavy lifting,
        // for example downloading or creating content etc, should be deferred to onDataSetChanged()
        // or getViewAt(). Taking more than 20 seconds in this call will result in an ANR.
    }

    override fun onDestroy() {
        // In onDestroy() you should tear down anything that was setup for your data source,
        // eg. cursors, connections, etc.
    }

    override fun onDataSetChanged() {
        // This is triggered when you call AppWidgetManager notifyAppWidgetViewDataChanged
        // on the collection view corresponding to this factory. You can do heaving lifting in
        // here, synchronously. For example, if you need to process an image, fetch something
        // from the network, etc., it is ok to do it here, synchronously. The widget will remain
        // in its current state while work is being done here, so you don't need to worry about
        // locking up the widget.
        textColor = intent.getIntExtra(EXTRA_ITEM_TEXTCOLOR, -1)
        val list: ArrayList<NoteItem> = arrayListOf()
        val noteListString = intent.getStringExtra(EXTRA_NOTELIST)
        val jsonArray = JSONTokener(noteListString).nextValue() as JSONArray
        for (i in 0 until jsonArray.length()) {
            val note = jsonArray.getJSONObject(i)
            list.add(NoteItem(note.getInt("id"), note.getString("text")))
        }
        data = list
    }

    override fun getLoadingView(): RemoteViews? {
        // You can create a custom loading view (for instance when getViewAt() is slow.) If you
        // return null here, you will get the default loading view.
        return null
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun hasStableIds(): Boolean {
        return true
    }

    override fun getCount(): Int {
        return data.size
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun getViewAt(position: Int): RemoteViews {
        println("-----------------------------------------------------------------getViewAt")
        var views = RemoteViews(context.packageName, R.layout.ohnote_widget_listviewitem)
        var bundle = Bundle().apply { 
            putInt(EXTRA_ITEM_NOTEID, data[position].id)
        }
        val intent = Intent().apply {
            putExtras(bundle)
        }
        views.setOnClickFillInIntent(R.id.rowTextView, intent)
        if (textColor != -1) {
            views.setTextColor(R.id.rowTextView, textColor)
        }
        println("-----------------------------------------------------------------getViewAt: setOnClickFillInIntent")
        views.setTextViewText(R.id.rowTextView, data[position].text)
        if (position == data.count() - 1) {
            views.setViewLayoutHeight(R.id.rowLayout, 25f, TypedValue.COMPLEX_UNIT_DIP)
        } else {
            views.setViewLayoutHeight(R.id.rowLayout, 20f, TypedValue.COMPLEX_UNIT_DIP)
        }
        return views
    }

    private class NoteItem(val id: Int, val text: String)
}

private fun getSystemDefaultRootLayoutId(opacity: Int): Int {
    return when (opacity) {
        100 -> R.layout.ohnote_widget_root
        95 -> R.layout.ohnote_widget_root_95
        90 -> R.layout.ohnote_widget_root_90
        85 -> R.layout.ohnote_widget_root_85
        80 -> R.layout.ohnote_widget_root_80
        75 -> R.layout.ohnote_widget_root_75
        70 -> R.layout.ohnote_widget_root_70
        65 -> R.layout.ohnote_widget_root_65
        60 -> R.layout.ohnote_widget_root_60
        55 -> R.layout.ohnote_widget_root_55
        50 -> R.layout.ohnote_widget_root_50
        45 -> R.layout.ohnote_widget_root_45
        40 -> R.layout.ohnote_widget_root_40
        35 -> R.layout.ohnote_widget_root_35
        30 -> R.layout.ohnote_widget_root_30
        25 -> R.layout.ohnote_widget_root_25
        20 -> R.layout.ohnote_widget_root_20
        15 -> R.layout.ohnote_widget_root_15
        10 -> R.layout.ohnote_widget_root_10
        5 -> R.layout.ohnote_widget_root_5
        else -> R.layout.ohnote_widget_root
    }
}