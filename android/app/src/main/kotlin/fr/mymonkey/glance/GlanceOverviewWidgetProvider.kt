package fr.mymonkey.glance

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget « Aperçu » Glance (Android) — pendant de GlanceOverviewWidget (iOS).
 *
 * Lit les données publiées par l'app (`WidgetPublisher.publish`) dans les
 * SharedPreferences partagées de home_widget, puis peuple le layout :
 * total + delta, courbe, et top des sites. Dessin (sparkline/delta/format)
 * factorisé dans [WidgetDraw].
 */
class GlanceOverviewWidgetProvider : HomeWidgetProvider() {

    // IDs des 5 lignes de sites (le layout expose des vues explicites).
    private data class RowIds(
        val row: Int, val name: Int, val spark: Int, val value: Int, val delta: Int,
    )

    private val rows = listOf(
        RowIds(R.id.w_row_0, R.id.w_name_0, R.id.w_rowspark_0, R.id.w_value_0, R.id.w_delta_0),
        RowIds(R.id.w_row_1, R.id.w_name_1, R.id.w_rowspark_1, R.id.w_value_1, R.id.w_delta_1),
        RowIds(R.id.w_row_2, R.id.w_name_2, R.id.w_rowspark_2, R.id.w_value_2, R.id.w_delta_2),
        RowIds(R.id.w_row_3, R.id.w_name_3, R.id.w_rowspark_3, R.id.w_value_3, R.id.w_delta_3),
        RowIds(R.id.w_row_4, R.id.w_name_4, R.id.w_rowspark_4, R.id.w_value_4, R.id.w_delta_4),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val accent = ContextCompat.getColor(context, R.color.gt_accent)
        val neg = ContextCompat.getColor(context, R.color.gt_neg)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.glance_widget)

            val hasData = widgetData.all["updated_at"] != null
            if (!hasData) {
                views.setViewVisibility(R.id.w_empty, View.VISIBLE)
                views.setViewVisibility(R.id.w_rows, View.GONE)
                views.setViewVisibility(R.id.w_spark, View.GONE)
                views.setViewVisibility(R.id.w_total_delta, View.GONE)
                views.setTextViewText(R.id.w_total, "—")
                views.setTextViewText(R.id.w_period, "")
                bindClick(context, views)
                appWidgetManager.updateAppWidget(widgetId, views)
                continue
            }

            views.setViewVisibility(R.id.w_empty, View.GONE)
            views.setViewVisibility(R.id.w_rows, View.VISIBLE)
            views.setViewVisibility(R.id.w_spark, View.VISIBLE)

            // En-tête : période + total + delta.
            views.setTextViewText(R.id.w_period, widgetData.string("period_label"))
            views.setTextViewText(R.id.w_total, WidgetDraw.fmtInt(widgetData.int("total_visitors")))
            WidgetDraw.bindDelta(views, R.id.w_total_delta, widgetData.optDouble("total_delta"), accent, neg)

            // Courbe totale (pleine largeur).
            val totalSpark = WidgetDraw.parseSpark(widgetData.string("total_spark"))
            if (totalSpark.size > 1) {
                views.setImageViewBitmap(
                    R.id.w_spark,
                    WidgetDraw.sparkBitmap(
                        totalSpark, WidgetDraw.dp(context, 320f), WidgetDraw.dp(context, 46f),
                        accent, WidgetDraw.dp(context, 2f).toFloat(),
                    ),
                )
            } else {
                views.setViewVisibility(R.id.w_spark, View.GONE)
            }

            // Top sites.
            val n = widgetData.int("site_count").coerceAtMost(rows.size)
            rows.forEachIndexed { i, ids ->
                if (i < n) {
                    views.setViewVisibility(ids.row, View.VISIBLE)
                    views.setTextViewText(ids.name, widgetData.string("site_${i}_name").ifEmpty { "—" })
                    views.setTextViewText(ids.value, WidgetDraw.fmtInt(widgetData.int("site_${i}_value")))
                    WidgetDraw.bindDelta(views, ids.delta, widgetData.optDouble("site_${i}_delta"), accent, neg)

                    val spark = WidgetDraw.parseSpark(widgetData.string("site_${i}_spark"))
                    if (spark.size > 1) {
                        views.setViewVisibility(ids.spark, View.VISIBLE)
                        views.setImageViewBitmap(
                            ids.spark,
                            WidgetDraw.sparkBitmap(
                                spark, WidgetDraw.dp(context, 32f), WidgetDraw.dp(context, 14f),
                                WidgetDraw.withAlpha(accent, 0.8f), WidgetDraw.dp(context, 1.5f).toFloat(),
                            ),
                        )
                    } else {
                        views.setViewVisibility(ids.spark, View.INVISIBLE)
                    }
                } else {
                    views.setViewVisibility(ids.row, View.GONE)
                }
            }

            bindClick(context, views)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindClick(context: Context, views: RemoteViews) {
        val intent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        views.setOnClickPendingIntent(R.id.widget_root, intent)
    }

    // Lectures typées robustes : home_widget stocke selon le type Dart
    // (int→Int/Long, double→Float), donc on coerce depuis la valeur brute.
    private fun SharedPreferences.string(key: String): String =
        all[key]?.toString() ?: ""

    private fun SharedPreferences.int(key: String): Int =
        (all[key] as? Number)?.toInt() ?: 0

    private fun SharedPreferences.optDouble(key: String): Double? =
        (all[key] as? Number)?.toDouble()
}
