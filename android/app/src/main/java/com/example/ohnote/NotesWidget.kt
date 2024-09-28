package com.example.ohnote // Your package name

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.net.Uri
import android.content.Intent
import android.app.PendingIntent
import android.os.Bundle
import org.json.JSONObject
import org.json.JSONTokener
import org.json.JSONArray
import es.antonborri.home_widget.HomeWidgetLaunchIntent

private const val APP_SCHEME_NAME = "ohnotewidget"
private const val EXTRA_NOTELIST = "com.example.ohnote.EXTRA_NOTELIST"
private const val EXTRA_NOTEID = "com.example.ohnote.EXTRA_NOTEID"
private const val OPEN_ACTION = "com.example.ohnote.OPEN_ACTION"

/*
 * Implementation of App Widget functionality.
 * App Widget Configuration implemented in [NotesWidgetConfigureActivity]
 */
class NotesWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // Enter relevant functionality for when the user deletes the widget
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Called when the BroadcastReceiver receives an Intent broadcast.
        if (intent.action == OPEN_ACTION) {
            openApp(context, intent)
        }
        super.onReceive(context, intent)
    }
}

internal fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
    val listViewIntent = Intent(context, NoteListViewWidgetService::class.java).apply {
        // Add the widget ID to the intent extras.
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        putExtra(EXTRA_NOTELIST, loadNotesPref(context))
        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
    }

    val views = RemoteViews(context.packageName, R.layout.notes_widget).apply {
        // PendingIntent to open app on widget click
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("$APP_SCHEME_NAME://opennote?id=0"))
        setOnClickPendingIntent(R.id.notes_widget_root, pendingIntent)
        
        setRemoteAdapter(R.id.noteListView, listViewIntent)

        // The empty view is displayed when the collection has no items.
        // It must be in the same layout used to instantiate the RemoteViews object.
        setEmptyView(R.id.noteListView, R.id.loadingTextView)

        // This section makes it possible for items to have individualized. It does this by setting up a pending intent template.
        // Individuals items of a collection can't set up their own pending intents. Instead, the collection as a whole sets up a pending
        // intent template, and the individual items set a fillInIntent to create unique behavior on an item-by-item basis.
        val pendingIntentTemplate = Intent(context, NotesWidget::class.java).run {
            action = OPEN_ACTION
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            PendingIntent.getBroadcast(context, 0, this, PendingIntent.FLAG_MUTABLE)
        }
        setPendingIntentTemplate(R.id.noteListView, pendingIntentTemplate)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

internal fun openApp(context: Context, intent: Intent) {
    val noteId = intent.getIntExtra(EXTRA_NOTEID, 0)
    val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("$APP_SCHEME_NAME://opennote?id=$noteId"))
    pendingIntent.send()
}

class NoteListViewWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return NoteListViewAdapter(this.applicationContext, intent)
    }
}

class NoteListViewAdapter(val context: Context, val intent: Intent) : RemoteViewsService.RemoteViewsFactory {
    private var data: ArrayList<ListViewItem> = arrayListOf()
    private val remoteViews = RemoteViews(context.packageName, R.layout.notes_widget_listview)
        
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
        val list: ArrayList<ListViewItem> = arrayListOf()
        val jsonArray = JSONTokener(intent.getStringExtra(EXTRA_NOTELIST)).nextValue() as JSONArray
        for (i in 0 until jsonArray.length()) {
            val note = jsonArray.getJSONObject(i)
            list.add(ListViewItem(note.getInt("id"), note.getString("text")))
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
        remoteViews.setTextViewText(R.id.rowTextView, data[position].text)
        var bundle = Bundle().apply { 
            putInt(EXTRA_NOTEID, data[position].id)
        }
        val intent = Intent().apply {
            putExtras(bundle)
        }
        remoteViews.setOnClickFillInIntent(R.id.rowTextView, intent)
        return remoteViews
    }

    private class ListViewItem(val id: Int, val text: String);
}