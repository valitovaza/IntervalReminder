import Foundation
protocol NotificationPresenterProtocol {
    func presentNotification(_ title: String)
}
protocol NotificationDeliverer {
    func deliver(_ notification: NSUserNotification)
    var delegate: NSUserNotificationCenterDelegate? {get set}
}
extension NSUserNotificationCenter: NotificationDeliverer {}
class NotificationPresenter: NSObject, NotificationPresenterProtocol, NSUserNotificationCenterDelegate {
    var deliverer: NotificationDeliverer!
    init(deliverer: NotificationDeliverer = NSUserNotificationCenter.default) {
        self.deliverer = deliverer
    }
    func presentNotification(_ title: String) {
        deliverer.delegate = self
        deliverer.deliver(notification(title))
    }
    private func notification(_ title: String) -> NSUserNotification {
        let notification = NSUserNotification()
        notification.title = "IntervalReminder"
        notification.informativeText = title
        notification.soundName = NSUserNotificationDefaultSoundName
        return notification
    }
    
    // MARK: - NSUserNotificationCenterDelegate
    func userNotificationCenter(_ center: NSUserNotificationCenter,
                                shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}
