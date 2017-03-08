import Foundation
protocol NotificationPresenterProtocol {
    func presentNotification(_ title: String)
}
protocol NotificationDeliverer {
    func deliver(_ notification: NSUserNotification)
}
extension NSUserNotificationCenter: NotificationDeliverer {}
struct NotificationPresenter: NotificationPresenterProtocol {
    let deliverer: NotificationDeliverer!
    init(deliverer: NotificationDeliverer = NSUserNotificationCenter.default) {
        self.deliverer = deliverer
    }
    func presentNotification(_ title: String) {
        deliverer.deliver(notification(title))
    }
    private func notification(_ title: String) -> NSUserNotification {
        let notification = NSUserNotification()
        notification.title = "IntervalReminder"
        notification.informativeText = title
        notification.soundName = NSUserNotificationDefaultSoundName
        return notification
    }
}
