package com.trendsapps.ohnote

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.LayoutInflater
import android.widget.ArrayAdapter
import android.widget.TextView
import android.widget.ListView
import android.widget.EditText
import android.net.Uri
import org.json.JSONObject
import org.json.JSONTokener
import org.json.JSONArray
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import com.trendsapps.ohnote.databinding.OhnoteWidgetConfigureBinding //layout/ohnote_widget_configure.xml

internal const val OPEN_HOMEWIDGETCONFIGS = "openhomewidgetconfigs"
internal const val PREF_CONFIG_IDS = "_ohNoteWidgetConfigIds"
internal const val PREF_CONFIG_ID = "_ohNoteWidgetConfigId_"
internal const val PREF_CONFIG = "_ohNoteWidgetConfig_"
internal const val PREF_NOTELIST = "_ohNoteWidgetList_"

/*
 * The configuration screen for the [OhNoteWidget] AppWidget.
 */
class OhNoteWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var binding: OhnoteWidgetConfigureBinding
    // private lateinit var appWidgetText: EditText
    private var selectedConfigId = -1
    
    private var onDoneClickListener = View.OnClickListener {
        val context = this@OhNoteWidgetConfigureActivity

        // // When the button is clicked, store the string locally
        // val widgetText = appWidgetText.text.toString()
        // saveTitlePref(context, appWidgetId, widgetText)

        val appWidgetManager = AppWidgetManager.getInstance(context)
        val prefs = HomeWidgetPlugin.getData(context)

        setConfigId(context, appWidgetId, selectedConfigId, prefs)
        
        // It is the responsibility of the configuration activity to update the app widget
        updateAppWidget(context, appWidgetManager, appWidgetId, prefs)

        // Make sure we pass back the original appWidgetId
        val resultValue = Intent()
        resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }

    private var onNewConfigurationClickListener = View.OnClickListener {
        val context = this@OhNoteWidgetConfigureActivity
        val activity = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("$APP_SCHEME_NAME://$OPEN_HOMEWIDGETCONFIGS"))
        activity.send()
        finish()
    }

    private var onCancelClickListener = View.OnClickListener {
        finish()
    }

    public override fun onCreate(icicle: Bundle?) {
        super.onCreate(icicle)

        // Set the result to CANCELED.  This will cause the widget host to cancel
        // out of the widget placement if the user presses the back button.
        setResult(RESULT_CANCELED)

        binding = OhnoteWidgetConfigureBinding.inflate(layoutInflater)
        setContentView(binding.root)

        getActionBar()?.setTitle(" Widget Configuration")

        // Find the widget id from the intent.
        if (intent?.extras != null) {
            appWidgetId = intent!!.extras!!.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        }
        // If this activity was started with an intent without an app widget ID, finish with an error.
         if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val context = this@OhNoteWidgetConfigureActivity
        val prefs = HomeWidgetPlugin.getData(context)
        // appWidgetText = binding.appwidgetText as EditText

        binding.doneButton.setOnClickListener(onDoneClickListener)
        binding.newConfigurationButton.setOnClickListener(onNewConfigurationClickListener)
        binding.cancelButton.setOnClickListener(onCancelClickListener)
        
        val configurationsArray = buildConfigurationsArray(prefs)
        val configurationsAdapter = ConfigurationsListViewAdapter(context, configurationsArray)
        binding.configListview.adapter = configurationsAdapter
        binding.configListview.emptyView = binding.configEmpty
        binding.configListview.choiceMode = ListView.CHOICE_MODE_SINGLE
        binding.configListview.setOnItemClickListener { parent, view, position, id ->
            binding.configListview.setItemChecked(position, true)
            selectedConfigId = configurationsAdapter.selectConfigItem(position)
            if (selectedConfigId > 0) {
                binding.doneButton.isEnabled = true
                binding.doneButton.isClickable = true
            }
        }
    }
}

private fun buildConfigurationsArray(prefs: SharedPreferences): ArrayList<ConfigurationItem> {
    val arrayList: ArrayList<ConfigurationItem> = arrayListOf()
    var configIdsString = prefs.getString(PREF_CONFIG_IDS, "[]")!!
    if (configIdsString != "[]") {
        configIdsString = configIdsString.substring(1, configIdsString.length - 1)
        val configIds = configIdsString.split(",")
        for (configId in configIds) {
            val configItem = buildConfigurationItem(prefs.getString("$PREF_CONFIG$configId", "")!!)
            if (configItem != null) {
                arrayList.add(configItem!!)
            }
        }
        arrayList.sortBy{ it.creationDateTime }
    }
    return arrayList
}

private fun buildConfigurationItem(configString: String): ConfigurationItem? {
    if (configString != ""){
        val configJson = JSONTokener(configString).nextValue() as JSONObject
        val filters = ArrayList<String>()
        val filtersJsonArray = configJson.getJSONArray("filters")
        for (i in 0 until filtersJsonArray.length()) {
            filters.add(filtersJsonArray.getString(i))
        }
        return ConfigurationItem(
            configJson.getInt("id"), 
            configJson.getString("title"), 
            configJson.getString("theme"), 
            configJson.getInt("opacity"), 
            configJson.getString("creation_datetime"),
            filters)
    }
    return null
}

private fun setConfigId(context: Context, appWidgetId: Int, configId: Int, prefs: SharedPreferences) {
    val prefsEdit = prefs.edit()
    prefsEdit.putInt("$PREF_CONFIG_ID$appWidgetId", configId)
    prefsEdit.apply()
}

internal fun getWidgetValues(context: Context, appWidgetId: Int, prefs: SharedPreferences): WidgetValues {
    var configString = ""
    var noteListString = "[]"
    var configItem: ConfigurationItem? = null
    var configId = prefs.getInt("$PREF_CONFIG_ID$appWidgetId", -1)
    if (configId > 0) {
        configString = prefs.getString("$PREF_CONFIG$configId", "")!!
        if (configString == "\"[REMOVED]\"") {
            configId = 0
            setConfigId(context, appWidgetId, 0, prefs)
        } else if (configString == "") {
            configId = -1
        } else {
            configItem = buildConfigurationItem(configString)
            noteListString = prefs.getString("$PREF_NOTELIST$configId", "[]")!!
        }
    }
    return WidgetValues(configId, configItem, noteListString)
}

internal fun deleteConfigId(context: Context, appWidgetId: Int, prefs: SharedPreferences) {
    val prefsEdit = prefs.edit()
    prefsEdit.remove("$PREF_CONFIG_ID$appWidgetId")
    prefsEdit.apply()
}

class ConfigurationItem(
    val id: Int, 
    val title: String, 
    val theme: String, 
    val opacity: Int, 
    val creationDateTime: String, 
    val filters: ArrayList<String>)

class WidgetValues(
    val configId: Int,
    val configItem: ConfigurationItem?,
    val noteListString: String)

class ConfigurationsListViewAdapter(context: Context, items: ArrayList<ConfigurationItem>) : ArrayAdapter<ConfigurationItem>(context, 0, items) {
    private var selectedPosition: Int = -1

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        val view = convertView ?: LayoutInflater.from(context).inflate(R.layout.ohnote_widget_configure_listviewitem, parent, false)
        val configItem = getItem(position)!!
        view.findViewById<TextView>(R.id.row_title_textview).text = configItem.title
        view.findViewById<TextView>(R.id.row_desc_textview).text = "${configItem.theme}, ${configItem.opacity}% opacity${getFiltersString(configItem.filters)}"
        if (position == selectedPosition) {
            view.setBackgroundColor(context.getColor(R.color.widget_selected_item))
        } else {
            view.setBackgroundColor(context.getColor(R.color.transparent))
        }
        return view
    }

    private fun getFiltersString(filters: ArrayList<String>): String {
        if (filters.count() > 0) {
            val joinedFilters = filters.joinToString(separator = ", ").lowercase()
            return ", filters: $joinedFilters"
        }
        return ""
    }

    fun selectConfigItem(position: Int) : Int {
        selectedPosition = position
        notifyDataSetChanged() 
        return getItem(position)!!.id
    }
}

// //Service added in AndroidManifest.xml
// class ConfigurationsListViewWidgetService : RemoteViewsService() {
//     override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
//         return ConfigurationsListViewAdapter(this.applicationContext, intent)
//     }
// }

// class ConfigurationsListViewAdapter(val context: Context, val intent: Intent) : RemoteViewsService.RemoteViewsFactory {
//     private var data: ArrayList<ConfigurationItem> = arrayListOf()
//     private val views = RemoteViews(context.packageName, R.layout.ohnote_widget_configure_listviewitem)

//     override fun onCreate() {}

//     override fun onDestroy() {}

//     override fun onDataSetChanged() {
//         data = getConfigurationsArray(intent.getStringExtra(EXTRA_CONFIGURATIONLIST))
//     }

//     override fun getLoadingView(): RemoteViews? { return null }

//     override fun getViewTypeCount(): Int { return 1 }

//     override fun hasStableIds(): Boolean { return true }

//     override fun getCount(): Int { return data.size }

//     override fun getItemId(position: Int): Long { return position.toLong() }

//     override fun getViewAt(position: Int): RemoteViews { return views }
// }