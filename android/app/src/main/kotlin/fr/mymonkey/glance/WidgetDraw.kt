package fr.mymonkey.glance

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

/** Dessin et format partagés par les widgets Glance (Aperçu + Site). */
object WidgetDraw {

    fun dp(context: Context, value: Float): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, value, context.resources.displayMetrics,
    ).roundToInt()

    fun fmtInt(n: Int): String {
        val symbols = DecimalFormatSymbols(Locale.FRANCE).apply {
            groupingSeparator = ' ' // espace fine insécable, comme iOS
        }
        return DecimalFormat("#,###", symbols).format(n.toLong())
    }

    fun parseSpark(csv: String): List<Double> =
        if (csv.isEmpty()) emptyList()
        else csv.split(",").mapNotNull { it.trim().toDoubleOrNull() }

    /** Delta ▲/▼ coloré (accent si hausse, neg sinon) ; masqué si null. */
    fun bindDelta(views: RemoteViews, id: Int, pct: Double?, accent: Int, neg: Int) {
        if (pct == null) {
            views.setViewVisibility(id, View.GONE)
            return
        }
        val up = pct >= 0
        val label = if (abs(pct) > 400) {
            "▲ ×${(pct / 100).roundToInt() + 1}"
        } else {
            "${if (up) "▲" else "▼"} ${abs(pct).roundToInt()} %"
        }
        views.setViewVisibility(id, View.VISIBLE)
        views.setTextViewText(id, label)
        views.setTextColor(id, if (up) accent else neg)
    }

    /** Sparkline tracée en Bitmap (RemoteViews ne dessine pas de lignes). */
    fun sparkBitmap(points: List<Double>, wPx: Int, hPx: Int, color: Int, stroke: Float): Bitmap {
        val bmp = Bitmap.createBitmap(
            wPx.coerceAtLeast(1), hPx.coerceAtLeast(1), Bitmap.Config.ARGB_8888,
        )
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

    fun withAlpha(color: Int, alpha: Float): Int {
        val a = (alpha * 255).roundToInt().coerceIn(0, 255)
        return (color and 0x00FFFFFF) or (a shl 24)
    }
}
