package fr.mymonkey.glance

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView

/**
 * Écran de configuration du widget par-site : liste les sites publiés et
 * mémorise celui choisi pour cet appWidgetId, puis rend le widget.
 */
class GlanceSiteConfigActivity : Activity() {

    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Par défaut : annulé (si l'utilisateur quitte sans choisir).
        setResult(RESULT_CANCELED)

        widgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.glance_site_config)
        val sites = loadAllSites(this)
        val empty = findViewById<TextView>(R.id.config_empty)
        val list = findViewById<ListView>(R.id.config_list)

        if (sites.isEmpty()) {
            empty.visibility = View.VISIBLE
            list.visibility = View.GONE
            return
        }

        empty.visibility = View.GONE
        list.adapter = ArrayAdapter(
            this, R.layout.glance_site_config_row, R.id.config_row_text, sites.map { it.name },
        )
        list.setOnItemClickListener { _, _, position, _ ->
            getSharedPreferences(GlanceSiteWidgetProvider.PREFS, MODE_PRIVATE).edit()
                .putString(GlanceSiteWidgetProvider.siteKey(widgetId), sites[position].id)
                .apply()
            GlanceSiteWidgetProvider.render(this, AppWidgetManager.getInstance(this), widgetId)
            setResult(
                RESULT_OK,
                Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
            )
            finish()
        }
    }
}
