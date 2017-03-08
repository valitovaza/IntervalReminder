protocol Configurator {
    func configure()
}
class AppConfigurator: Configurator {
    var statusBarManager = StatusBarManager()
    func configure() {
        statusBarManager.configure()
    }
}
