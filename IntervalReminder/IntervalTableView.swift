import Cocoa
enum TableViewMenu: String {
    case Delete
}
class IntervalTableView: NSTableView {
    var notificationCenter: NotificationCenterable = NotificationCenter.default
    private var lastMouseRow = -1
    open override func menu(for event: NSEvent) -> NSMenu? {
        lastMouseRow = mouseRow(for: event)
        if selectedRow >= 0 || lastMouseRow >= 0 {
            return deleteMenu()
        }
        return nil
    }
    private func mouseRow(for event: NSEvent) -> Int {
        let mousePoint = convert(event.locationInWindow, from: nil)
        return row(at: mousePoint)
    }
    private func deleteMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: TableViewMenu.Delete.rawValue,
                                action: #selector(deleteInterval), keyEquivalent: ""))
        return menu
    }
    @objc func deleteInterval() {
        let index = lastMouseRow >= 0 ? lastMouseRow : selectedRow
        let notification = Notification(name: Notification.Name.IntervalReminderNotifications.DeleteFromMenu.name,
                                        object: nil,
                                        userInfo: [IntervalReminderKeys.deleteIndex.value: index])
        notificationCenter.post(notification)
    }
}
