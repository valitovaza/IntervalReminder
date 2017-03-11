import Foundation
enum IntervalReminderKeys: String {
    case reminderInterval
    case reminderPastInterval
    case deleteIndex
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
protocol NotificationCenterable {
    func post(_ notification: Notification)
    func addObserver(forName name: NSNotification.Name?, object obj: Any?,
                     queue: OperationQueue?,
                     using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol
    func removeObserver(_ observer: Any)
}
extension NotificationCenter: NotificationCenterable {}
