import Cocoa
protocol Applicationable {
    func activate(ignoringOtherApps flag: Bool)
    func terminate(_ sender: Any?)
    var windows: [NSWindow] { get }
}
extension NSApplication: Applicationable {}
protocol NotificationCenterable {
    func post(_ notification: Notification)
    func addObserver(forName name: NSNotification.Name?, object obj: Any?,
                     queue: OperationQueue?,
                     using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol
    func removeObserver(_ observer: Any)
}
extension NotificationCenter: NotificationCenterable {}
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
protocol KeyNamespaceable { }
extension KeyNamespaceable {
    static func namespace<T>(_ key: T) -> String where T: RawRepresentable {
        return "\(Self.self).\(key.rawValue)"
    }
}
enum IntervalReminderKeys: String {
    case reminderInterval
    case reminderPastInterval
    case deleteIndex
    var value: String {
        return self.rawValue
    }
}
extension Notification.Name {
    enum IntervalReminderNotifications: String, KeyNamespaceable {
        case StartFromStatusbar
        case PauseFromStatusbar
        case ResumeFromStatusbar
        case StopFromStatusbar
        case DeleteFromMenu
        case IntervalStarted
        case IntervalStopped
        case IntervalResumed
        case IntervalEnded
        var value: String {
            return IntervalReminderNotifications.namespace(self)
        }
        var name: Notification.Name {
            return Notification.Name(self.value)
        }
        var notification: Notification {
            return Notification(name: name)
        }
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
