package fr.mymonkey.glance

import android.content.Context
import org.json.JSONArray

/** Un site tel que publié par l'app dans `all_sites` (JSON, clés courtes). */
data class SiteRecord(
    val id: String,
    val name: String,
    val visitors: Int,
    val pageviews: Int,
    val delta: Double?,
    val spark: List<Double>,
)

/** Prefs partagées écrites par home_widget (`WidgetPublisher.publish`). */
const val HOME_WIDGET_PREFS = "HomeWidgetPreferences"

/** Tous les sites publiés (pour le sélecteur + le rendu du widget par-site). */
fun loadAllSites(context: Context): List<SiteRecord> {
    val json = context.getSharedPreferences(HOME_WIDGET_PREFS, Context.MODE_PRIVATE)
        .getString("all_sites", null) ?: return emptyList()
    return try {
        val arr = JSONArray(json)
        (0 until arr.length()).map { idx ->
            val o = arr.getJSONObject(idx)
            SiteRecord(
                id = o.optString("i"),
                name = o.optString("n"),
                visitors = o.optInt("v"),
                pageviews = o.optInt("p"),
                delta = if (o.has("d") && !o.isNull("d")) o.optDouble("d") else null,
                spark = WidgetDraw.parseSpark(o.optString("s")),
            )
        }
    } catch (e: Exception) {
        emptyList()
    }
}

fun widgetPeriodLabel(context: Context): String =
    context.getSharedPreferences(HOME_WIDGET_PREFS, Context.MODE_PRIVATE)
        .getString("period_label", "") ?: ""
