import Cocoa
protocol Applicationable {
    func activate(ignoringOtherApps flag: Bool)
    func terminate(_ sender: Any?)
    var windows: [NSWindow] { get }
}
extension NSApplication: Applicationable {}
enum MenuTitles: String {
    case Start
    case Pause
    case Resume
    case Stop
    case Show
    case Hide
    case Quit
    var value: String {
        return self.rawValue
    }
}
class StatusBarManager: EventListenerDelegate {
    let statusItem = NSStatusBar.system().statusItem(withLength: -2)
    var activatable: Applicationable = NSApp
    var notificationCenter: NotificationCenterable = NotificationCenter.default
    private(set) var repeaterListener: RepeaterEventListener!
    func configure() {
        activatable.activate(ignoringOtherApps: true)
        configureStatusBarButton()
        statusItem.menu = NSMenu()
        addInitialItems()
    }
    private func configureStatusBarButton() {
        if let button = statusItem.button {
            repeaterListener = RepeaterEventListener(button)
            repeaterListener.delegate = self
        }
    }
    private func addInitialItems() {
        let menu = clearedMenu()
        menu.addItem(itemWith(title: MenuTitles.Start.value,
                              action: #selector(start(sender:))))
        addSeparatorAndLastItems(menu)
    }
    private func addInProgressItems() {
        let menu = clearedMenu()
        menu.addItem(itemWith(title: MenuTitles.Pause.value,
                              action: #selector(pause(sender:))))
        menu.addItem(itemWith(title: MenuTitles.Stop.value,
                              action: #selector(stop(sender:))))
        addSeparatorAndLastItems(menu)
    }
    private func addStoppedItems() {
        let menu = clearedMenu()
        menu.addItem(itemWith(title: MenuTitles.Resume.value,
                              action: #selector(resume(sender:))))
        menu.addItem(itemWith(title: MenuTitles.Stop.value,
                              action: #selector(stop(sender:))))
        addSeparatorAndLastItems(menu)
    }
    private func clearedMenu() -> NSMenu {
        let menu = statusItem.menu!
        menu.removeAllItems()
        return menu
    }
    private func addSeparatorAndLastItems(_ menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())
        menu.addItem(itemWith(title: MenuTitles.Show.value,
                              action: #selector(show(sender:))))
        menu.addItem(itemWith(title: MenuTitles.Quit.value,
                              action: #selector(quit(sender:))))
    }
    private func itemWith(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title,
                              action: action, keyEquivalent: "")
        item.target = self
        return item
    }
    @objc func start(sender: AnyObject) {
        notificationCenter.post(Notification.Name.IntervalReminderNotifications.StartFromStatusbar.notification)
    }
    @objc func pause(sender: AnyObject) {
        notificationCenter.post(Notification.Name.IntervalReminderNotifications.PauseFromStatusbar.notification)
    }
    @objc func stop(sender: AnyObject) {
        notificationCenter.post(Notification.Name.IntervalReminderNotifications.StopFromStatusbar.notification)
    }
    @objc func resume(sender: AnyObject) {
        notificationCenter.post(Notification.Name.IntervalReminderNotifications.ResumeFromStatusbar.notification)
    }
    @objc func show(sender: AnyObject) {
        activatable.activate(ignoringOtherApps: true)
        for window in activatable.windows {
            window.makeKeyAndOrderFront(nil)
        }
    }
    @objc func quit(sender: AnyObject) {
        activatable.terminate(NSApp)
    }
    
    // MARK: - EventListenerDelegate
    func intervalStarted() {
        addInProgressItems()
    }
    func intervalStopped() {
        addStoppedItems()
    }
    func intervalResumed() {
        addInProgressItems()
    }
    func intervalEnded(){
        addInitialItems()
    }
}
