import Cocoa
import FlutterMacOS
import WidgetKit

class MainFlutterWindow: NSWindow {
  // Retenu pour la durée de vie de la fenêtre (sinon le handler est libéré).
  private var widgetChannel: FlutterMethodChannel?

  // App Group partagé avec l'extension widget. Sur macOS l'identifiant DOIT être
  // préfixé par le Team ID (contrairement à iOS).
  private static let appGroup = "5C67TFSJ2B.group.fr.mymonkey.glance"

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Taille par défaut adaptée au shell master-détail + taille minimale pour
    // rester au-dessus du point de bascule desktop.
    self.setContentSize(NSSize(width: 1200, height: 820))
    self.contentMinSize = NSSize(width: 900, height: 600)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Pont widgets macOS : le plugin home_widget n'a pas d'implémentation macOS,
    // on écrit donc nous-mêmes les données dans l'App Group (partagé avec
    // l'extension WidgetKit) puis on recharge les timelines.
    let channel = FlutterMethodChannel(
      name: "fr.mymonkey.glance/widget",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      MainFlutterWindow.handle(call, result)
    }
    self.widgetChannel = channel

    super.awakeFromNib()
  }

  private static func handle(_ call: FlutterMethodCall, _ result: FlutterResult) {
    switch call.method {
    case "saveData":
      guard let args = call.arguments as? [String: Any],
            let defaults = UserDefaults(suiteName: appGroup) else {
        result(false)
        return
      }
      for (key, value) in args {
        if value is NSNull {
          defaults.removeObject(forKey: key)
        } else {
          defaults.set(value, forKey: key)
        }
      }
      result(true)
    case "reload":
      if #available(macOS 11.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
