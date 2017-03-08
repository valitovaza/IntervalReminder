import Cocoa
protocol EventListenerDelegate: class {
    func intervalStarted()
    func intervalStopped()
    func intervalResumed()
    func intervalEnded()
}
class RepeaterEventListener: ImageChangeListener {
    private(set) var statusButton: NSStatusBarButton!
    private var imageGenerator: ImageGeneratable!
    private let notificationCenter: NotificationCenterable!
    private var timeScheduler: TimeScheduler!
    weak var delegate: EventListenerDelegate?
    init(_ statusButton: NSStatusBarButton,
         _ generator: ImageGeneratable = ImageGenerator(),
         _ notificationCenter: NotificationCenterable = NotificationCenter.default,
         _ timeScheduler: TimeScheduler = Timer()) {
        self.timeScheduler = timeScheduler
        self.notificationCenter = notificationCenter
        imageGenerator = generator
        self.statusButton = statusButton
        performInitConfigurations()
    }
    private func performInitConfigurations() {
        self.statusButton.image = imageGenerator.generate()
        addObservers()
        imageGenerator.delegate = self
    }
    deinit {
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
        stopTimer()
    }
    private var observers: [NSObjectProtocol] = []
    private func addObservers() {
        addObserver(Notification.Name.IntervalReminderNotifications.IntervalStarted.name)
        addObserver(Notification.Name.IntervalReminderNotifications.IntervalStopped.name)
        addObserver(Notification.Name.IntervalReminderNotifications.IntervalResumed.name)
        addObserver(Notification.Name.IntervalReminderNotifications.IntervalEnded.name)
    }
    private func addObserver(_ name: Notification.Name) {
        let observer = notificationCenter.addObserver(forName: name,
                                                      object: nil,
                                                      queue: OperationQueue.main)
        {[weak self]notification in
            guard let strongSelf = self else {return}
            strongSelf.handleEvent(notification)
        }
        observers.append(observer)
    }
    private func handleEvent(_ notification: Notification) {
        switch notification.name {
        case Notification.Name.IntervalReminderNotifications.IntervalStarted.name:
            intervalStarted(notification)
        case Notification.Name.IntervalReminderNotifications.IntervalStopped.name:
            stopTimer()
            delegate?.intervalStopped()
        case Notification.Name.IntervalReminderNotifications.IntervalResumed.name:
            intervalResumed(notification)
        case Notification.Name.IntervalReminderNotifications.IntervalEnded.name:
            intervalEnded()
        default:
            break
        }
    }
    private func intervalStarted(_ notification: Notification) {
        setInterval(from: notification)
        imageGenerator.setPastInterval(0.0)
        scheduleInterval()
        delegate?.intervalStarted()
    }
    private func intervalResumed(_ notification: Notification) {
        setInterval(from: notification)
        setPastInterval(from: notification)
        scheduleInterval()
        delegate?.intervalResumed()
    }
    private func intervalEnded() {
        stopTimer()
        imageGenerator.setInterval(0.0)
        delegate?.intervalEnded()
    }
    private func setInterval(from notification: Notification) {
        if let interval = notification.userInfo?[IntervalReminderKeys.reminderInterval.value] as? Double {
            imageGenerator.setInterval(interval)
        }
    }
    private func setPastInterval(from notification: Notification) {
        if let interval = notification.userInfo?[IntervalReminderKeys.reminderPastInterval.value] as? Double {
            imageGenerator.setPastInterval(interval)
        }
    }
    private var timer: Timer?
    private func scheduleInterval() {
        timer = timeScheduler.scheduledTimer(withTimeInterval: 1.0,
                                             repeats: true)
        { [weak self](_) in
            self?.imageGenerator.incrementInterval()
        }
    }
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - ImageChangeListener
    func imageChanged(image: NSImage) {
        statusButton.image = image
    }
}
