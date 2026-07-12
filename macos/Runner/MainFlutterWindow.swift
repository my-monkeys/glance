import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Taille par défaut adaptée au shell master-détail + taille minimale pour
    // rester au-dessus du point de bascule desktop.
    self.setContentSize(NSSize(width: 1200, height: 820))
    self.contentMinSize = NSSize(width: 900, height: 600)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
