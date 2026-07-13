package fr.mymonkey.glance

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Widget « Site » Glance (Android) — pendant de GlanceSiteWidget (iOS).
 *
 * Affiche les visiteurs d'UN site choisi à l'ajout (via [GlanceSiteConfigActivity]).
 * Le site sélectionné est mémorisé par appWidgetId ; les données viennent de
 * `all_sites` publié par l'app. Dessin factorisé dans [WidgetDraw].
 */
class GlanceSiteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) render(context, appWidgetManager, id)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val edit = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        for (id in appWidgetIds) edit.remove(siteKey(id))
        edit.apply()
    }

    companion object {
        const val PREFS = "glance_site_widget"
        fun siteKey(widgetId: Int) = "site_$widgetId"

        /** Rend un widget par-site (appelé par onUpdate et par l'activité de config). */
        fun render(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            val accent = ContextCompat.getColor(context, R.color.gt_accent)
            val neg = ContextCompat.getColor(context, R.color.gt_neg)
            val views = RemoteViews(context.packageName, R.layout.glance_site_widget)

            val sites = loadAllSites(context)
            val selectedId = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(siteKey(widgetId), null)
            val rec = sites.firstOrNull { it.id == selectedId } ?: sites.firstOrNull()

            if (rec == null) {
                views.setViewVisibility(R.id.sw_content, View.GONE)
                views.setViewVisibility(R.id.sw_empty, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.sw_empty, View.GONE)
                views.setViewVisibility(R.id.sw_content, View.VISIBLE)
                views.setTextViewText(R.id.sw_name, rec.name)
                views.setTextViewText(R.id.sw_period, widgetPeriodLabel(context))
                views.setTextViewText(R.id.sw_value, WidgetDraw.fmtInt(rec.visitors))
                WidgetDraw.bindDelta(views, R.id.sw_delta, rec.delta, accent, neg)

                if (rec.spark.size > 1) {
                    views.setViewVisibility(R.id.sw_spark, View.VISIBLE)
                    views.setImageViewBitmap(
                        R.id.sw_spark,
                        WidgetDraw.sparkBitmap(
                            rec.spark, WidgetDraw.dp(context, 320f), WidgetDraw.dp(context, 44f),
                            accent, WidgetDraw.dp(context, 2f).toFloat(),
                        ),
                    )
                } else {
                    views.setViewVisibility(R.id.sw_spark, View.GONE)
                }
                views.setTextViewText(R.id.sw_pageviews, WidgetDraw.fmtInt(rec.pageviews))
            }

            views.setOnClickPendingIntent(
                R.id.sw_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
