import WidgetKit
import SwiftUI

// Point d'entrée de l'extension widget macOS. Les widgets eux-mêmes
// (GlanceOverviewWidget, GlanceSiteWidget) sont partagés avec iOS — cf. les
// fichiers GlanceWidget.swift / GlanceSiteWidget.swift, rendus cross-platform.
@main
struct GlanceMacWidgetBundle: WidgetBundle {
    var body: some Widget {
        GlanceOverviewWidget()
        if #available(macOS 14.0, *) {
            GlanceSiteWidget()
        }
    }
}
