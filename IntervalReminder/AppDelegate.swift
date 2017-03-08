import Cocoa
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var configurator: Configurator = AppConfigurator()
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        configurator.configure()
    }
}
