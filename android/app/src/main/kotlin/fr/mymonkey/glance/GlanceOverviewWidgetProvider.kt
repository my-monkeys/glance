package fr.mymonkey.glance

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Widget « Aperçu » Glance (Android) — pendant de GlanceOverviewWidget (iOS).
 *
 * Lit les données publiées par l'app (`WidgetPublisher.publish`) dans les
 * SharedPreferences partagées de home_widget, puis peuple le layout :
 * total + delta, courbe, et top des sites. Les sparklines sont dessinées en
 * Bitmap (Canvas) — RemoteViews ne sait pas tracer de lignes.
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
            views.setTextViewText(R.id.w_total, fmtInt(widgetData.int("total_visitors")))
            bindDelta(views, R.id.w_total_delta, widgetData.optDouble("total_delta"), accent, neg)

            // Courbe totale (pleine largeur).
            val totalSpark = parseSpark(widgetData.string("total_spark"))
            val w = dp(context, 320f)
            val h = dp(context, 46f)
            if (totalSpark.size > 1) {
                views.setImageViewBitmap(
                    R.id.w_spark, sparkBitmap(totalSpark, w, h, accent, dp(context, 2f).toFloat()),
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
                    views.setTextViewText(ids.value, fmtInt(widgetData.int("site_${i}_value")))
                    bindDelta(views, ids.delta, widgetData.optDouble("site_${i}_delta"), accent, neg)

                    val spark = parseSpark(widgetData.string("site_${i}_spark"))
                    if (spark.size > 1) {
                        views.setViewVisibility(ids.spark, View.VISIBLE)
                        views.setImageViewBitmap(
                            ids.spark,
                            sparkBitmap(spark, dp(context, 32f), dp(context, 14f),
                                withAlpha(accent, 0.8f), dp(context, 1.5f).toFloat()),
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

    private fun bindDelta(
        views: RemoteViews, id: Int, pct: Double?, accent: Int, neg: Int,
    ) {
        if (pct == null) {
            views.setViewVisibility(id, View.GONE)
            return
        }
        val up = pct >= 0
        val label = if (abs(pct) > 400) {
            "▲ ×${(pct / 100).roundToInt() + 1}"
        } else {
            val arrow = if (up) "▲" else "▼"
            "$arrow ${abs(pct).roundToInt()} %"
        }
        views.setViewVisibility(id, View.VISIBLE)
        views.setTextViewText(id, label)
        views.setTextColor(id, if (up) accent else neg)
    }

    // --- Dessin des sparklines -------------------------------------------------

    private fun sparkBitmap(
        points: List<Double>, wPx: Int, hPx: Int, color: Int, stroke: Float,
    ): Bitmap {
        val bmp = Bitmap.createBitmap(wPx.coerceAtLeast(1), hPx.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        val maxV = maxOf(points.max(), 1.0)
        val minV = minOf(points.min(), 0.0)
        val range = maxOf(maxV - minV, 1.0)
        // Marge verticale pour ne pas couper le trait aux bords.
        val pad = stroke
        val usableH = hPx - pad * 2
        val stepX = wPx.toFloat() / (points.size - 1)
        val path = Path()
        points.forEachIndexed { i, v ->
            val x = i * stepX
            val y = pad + (usableH - ((v - minV) / range).toFloat() * usableH)
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        canvas.drawPath(path, paint)
        return bmp
    }

    private fun withAlpha(color: Int, alpha: Float): Int {
        val a = (alpha * 255).roundToInt().coerceIn(0, 255)
        return (color and 0x00FFFFFF) or (a shl 24)
    }

    // --- Helpers ---------------------------------------------------------------

    private fun parseSpark(csv: String): List<Double> =
        if (csv.isEmpty()) emptyList()
        else csv.split(",").mapNotNull { it.trim().toDoubleOrNull() }

    private fun dp(context: Context, value: Float): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, value, context.resources.displayMetrics,
    ).roundToInt()

    private fun fmtInt(n: Int): String {
        val symbols = DecimalFormatSymbols(Locale.FRANCE).apply {
            groupingSeparator = ' ' // espace fine insécable, comme iOS
        }
        return DecimalFormat("#,###", symbols).format(n.toLong())
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
