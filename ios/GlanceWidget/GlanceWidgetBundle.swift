import WidgetKit
import SwiftUI

@main
struct GlanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        GlanceOverviewWidget()
        // Widget configurable « par site » : App Intents (iOS 17+).
        if #available(iOS 17.0, *) {
            GlanceSiteWidget()
        }
    }
}
