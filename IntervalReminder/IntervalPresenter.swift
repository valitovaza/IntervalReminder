import Cocoa
protocol IntervalPresenterProtocol: class {
    func count() -> Int
    func present(cell: NSTableCellView, at row: Int)
}
protocol IntervalDataProvider: class, IntervalKeeperProtocol {
    func count() -> Int
    func title(forRow row: Int) -> String
    func interval(forRow row: Int) -> Double
    func elapsedInterval(forRow row: Int) -> Double
    func start()
    func delete(at index: Int)
    func pause()
    func resume()
    var currentIndex: Int {get}
    func saveIntervals()
}

protocol IntervalsViewProtocol: class {
    weak var intervalButton: NSButton! {get}
    weak var stopButton: NSButton! {get}
    weak var createButton: NSButton! {get}
    func addRow(at index: Int)
    func removeRow(at index: Int)
    func updateRow(at index: Int)
    func reload()
}
enum ButtonTitles: String {
    case Start
    case Pause
    case Resume
}
class IntervalPresenter: IntervalPresenterProtocol, IntervalsChangePresenter {
    weak var dataProvider: IntervalDataProvider?
    weak var view: IntervalsViewProtocol?
    var notificationCenter: NotificationCenterable!
    var workspaceNotificationCenter: NotificationCenterable!
    
    init(_ view: IntervalsViewProtocol,
         _ notificationCenter: NotificationCenterable = NotificationCenter.default,
         _ workspaceNotificationCenter: NotificationCenterable = NSWorkspace.shared().notificationCenter) {
        self.notificationCenter = notificationCenter
        self.workspaceNotificationCenter = workspaceNotificationCenter
        self.view = view
        addObservers()
    }
    deinit {
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
        for observer in workspaceObservers {
            workspaceNotificationCenter.removeObserver(observer)
        }
    }
    private var observers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private func addObservers() {
        addObserver(Notification.Name.IntervalReminderNotifications.StartFromStatusbar.name)
        addObserver(Notification.Name.IntervalReminderNotifications.PauseFromStatusbar.name)
        addObserver(Notification.Name.IntervalReminderNotifications.ResumeFromStatusbar.name)
        addObserver(Notification.Name.IntervalReminderNotifications.StopFromStatusbar.name)
        addObserver(Notification.Name.IntervalReminderNotifications.DeleteFromMenu.name)
        addObserver(NSNotification.Name.NSApplicationWillTerminate)
        addWorkspaceObserver(NSNotification.Name.NSWorkspaceWillSleep)
    }
    private func addWorkspaceObserver(_ name: Notification.Name){
        workspaceObservers.append(addHandler(workspaceNotificationCenter, name))
    }
    private func addObserver(_ name: Notification.Name) {
        observers.append(addHandler(notificationCenter, name))
    }
    private func addHandler(_ notificationCenter: NotificationCenterable,
                            _ name: Notification.Name) -> NSObjectProtocol {
        return notificationCenter.addObserver(forName: name,
                                                      object: nil,
                                                      queue: OperationQueue.main)
        {[weak self]notification in
            guard let strongSelf = self else {return}
            strongSelf.handleEvent(notification)
        }
    }
    private func handleEvent(_ notification: Notification) {
        switch notification.name {
        case Notification.Name.IntervalReminderNotifications.StartFromStatusbar.name:
            dataProvider?.start()
        case Notification.Name.IntervalReminderNotifications.PauseFromStatusbar.name:
            dataProvider?.pause()
        case Notification.Name.IntervalReminderNotifications.ResumeFromStatusbar.name:
            dataProvider?.resume()
        case Notification.Name.IntervalReminderNotifications.StopFromStatusbar.name:
            dataProvider?.stop()
        case Notification.Name.IntervalReminderNotifications.DeleteFromMenu.name:
            delete(notification)
        case NSNotification.Name.NSWorkspaceWillSleep:
            dataProvider?.pause()
        case NSNotification.Name.NSApplicationWillTerminate:
            dataProvider?.saveIntervals()
        default:
            break
        }
    }
    private func delete(_ notification: Notification) {
        if let deleteIndex = deleteIndex(from: notification) {
            dataProvider?.delete(at: deleteIndex)
            view?.removeRow(at: deleteIndex)
        }
    }
    private func deleteIndex(from notification: Notification) -> Int? {
        return notification.userInfo?[IntervalReminderKeys.deleteIndex.value] as? Int
    }
    
    // MARK: - IntervalPresenterProtocol
    func count() -> Int {
        return dataProvider?.count() ?? 0
    }
    func present(cell: NSTableCellView, at row: Int) {
        let title = dataProvider!.title(forRow: row)
        let interval = dataProvider!.interval(forRow: row)
        cell.textField?.stringValue = textFor(row: row, title: title, interval: interval)
    }
    
    // MARK: - Auxiliary methods
    private func textFor(row: Int, title: String, interval: Double) -> String {
        if row == dataProvider!.currentIndex {
            return generateInProgressCellText(row, title, interval)
        }else{
            return generateCellText(title, interval)
        }
    }
    private func generateInProgressCellText(_ row: Int, _ title: String, _ interval: Double) -> String {
        let time = timeString(from: interval)
        let remained = timeString(from: dataProvider!.elapsedInterval(forRow: row))
        return "\(title) \(remained) - \(time)"
    }
    private func generateCellText(_ title: String, _ interval: Double) -> String {
        let time = timeString(from: interval)
        return "\(title) \(time)"
    }
    private func timeString(from interval: Double) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    // MARK: - IntervalsChangePresenter
    func newInterval(at index: Int) {
        view?.addRow(at: index)
    }
    func configureStopButton(inProgress: Bool) {
        view?.stopButton.isEnabled = inProgress
    }
    func configureIntervalButton(title: String) {
        view?.intervalButton.title = title
    }
    func enableIntervalButton() {
        view?.intervalButton.isEnabled = true
    }
    func disableIntervalButton() {
        view?.intervalButton.isEnabled = false
        view?.intervalButton.title = ButtonTitles.Start.rawValue
    }
    func updateProgress() {
        if let currentIndex = dataProvider?.currentIndex {
            view?.updateRow(at: currentIndex)
        }
    }
    func intervalStarted(_ interval: Double) {
        notificationCenter.post(Notification(name: Notification.Name.IntervalReminderNotifications.IntervalStarted.name,
                                             object: nil,
                                             userInfo: notificationInfo(interval)))
    }
    private func notificationInfo(_ interval: Double) -> [String: Any] {
        return [IntervalReminderKeys.reminderInterval.rawValue: interval]
    }
    func intervalStopped() {
        notificationCenter.post(Notification.Name.IntervalReminderNotifications.IntervalStopped.notification)
    }
    func intervalEnded() {
        notificationCenter.post(Notification.Name.IntervalReminderNotifications.IntervalEnded.notification)
    }
    func intervalResumed(elapsed: Double, interval: Double) {
        notificationCenter.post(Notification(name: Notification.Name.IntervalReminderNotifications.IntervalResumed.name,
                                             object: nil,
                                             userInfo: info(elapsed: elapsed, interval: interval)))
    }
    private func info(elapsed: Double, interval: Double) -> [String: Any] {
        return [IntervalReminderKeys.reminderInterval.rawValue: interval,
                IntervalReminderKeys.reminderPastInterval.rawValue: elapsed]
    }
    func reload() {
        view?.reload()
        configureIntervalButton()
    }
    private func configureIntervalButton() {
        if let dataProvider = dataProvider,
            dataProvider.count() > 0 {
            enableIntervalButton()
        }else{
            disableIntervalButton()
        }
    }
}
