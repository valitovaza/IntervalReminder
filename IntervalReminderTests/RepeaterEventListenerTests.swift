import XCTest
@testable import IntervalReminder
class RepeaterEventListenerTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let timeInterval: Double = 4.0
    private let pastTimeInterval: Double = 2.0
    
    // MARK: - Test variables
    private var sut: RepeaterEventListener!
    private var generator: MockGenerator!
    private var button: NSStatusBarButton!
    private var nc: MockNotificationCenter!
    private var timer: MockTimer!
    private var delegate: MockDelegate!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        initiateVariables()
        clearStatics()
    }
    private func initiateVariables() {
        button = NSStatusBarButton()
        generator = MockGenerator()
        nc = MockNotificationCenter()
        timer = MockTimer()
        sut = RepeaterEventListener(button, generator, nc, timer)
        delegate = MockDelegate()
        sut.delegate = delegate
    }
    private func clearStatics() {
        MockTimer.mockInterval = nil
        MockTimer.invalidateGotCalled = false
        MockTimer.mockRepeats = false
    }
    override func tearDown() {
        clearVariables()
        super.tearDown()
    }
    private func clearVariables() {
        sut = nil
        generator = nil
        button = nil
        timer = nil
        nc = nil
        delegate = nil
    }
    
    // MARK: - Tests
    func testSutIsntNil() {
        XCTAssertNotNil(sut, "SUT must not be nil.")
    }
    func testContainProvidedView() {
        XCTAssertEqual(sut.statusButton, button, "Must contain provided view")
    }
    func testGenerateGotCalledWithZero() {
        XCTAssertTrue(generator.generateGotInvoked,
                       "Generate got called")
    }
    func testObserversAddedInInit() {
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.IntervalStarted.name))
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.IntervalStopped.name))
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.IntervalResumed.name))
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.IntervalEnded.name))
    }
    func testRemoveObserverShouldBeInvokedWhenDeinit() {
        sut = nil
        XCTAssertEqual(nc.mockObservers.count, 0,
                       "All observers must be removed")
    }
    func testScheduleTimerGotCalledWhenIntervalStarted() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        XCTAssertEqual(MockTimer.mockInterval, 1.0,
                      "Timer should be fired when IntervalStarted")
    }
    func testGeneratorMustBeConfiguredWithIntervalStartedNotification() {
        let notification = Notification(name: Notification.Name.IntervalReminderNotifications.IntervalStarted.name, object: nil, userInfo: [IntervalReminderKeys.reminderInterval.value: timeInterval])
        nc.post(notification)
        XCTAssertEqual(generator.interval, timeInterval,
                       "Image generator must be configured by IntervalStarted")
    }
    func testScheduleTimerMustNotBeInvokedWhenIntervalStopped() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStopped.notification)
        XCTAssertNil(MockTimer.mockInterval,
                     "Timer must not react to IntervalStopped")
    }
    func testScheduleTimerMustRepeat() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        XCTAssertTrue(MockTimer.mockRepeats, "Timer must repeat")
    }
    func testInvalidateMustBeCalledWhenIntervalStopped() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStopped.notification)
        XCTAssertTrue(MockTimer.invalidateGotCalled,
                      "Invalidate must be called when IntervalStopped")
    }
    func testScheduleTimerGotCalledWhenIntervalResumed() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalResumed.notification)
        XCTAssertEqual(MockTimer.mockInterval, 1.0,
                       "Timer should be fired when IntervalResumed")
    }
    func testGeneratorMustBeConfiguredWithResumedNotification() {
        let notification = Notification(name: Notification.Name.IntervalReminderNotifications.IntervalResumed.name, object: nil, userInfo: [IntervalReminderKeys.reminderInterval.value: timeInterval, IntervalReminderKeys.reminderPastInterval.value: pastTimeInterval])
        nc.post(notification)
        XCTAssertEqual(generator.interval, timeInterval,
                       "Image generator must be configured by IntervalResumed")
        XCTAssertEqual(generator.pastinterval, pastTimeInterval,
                       "Image generator must be configured by IntervalResumed")
    }
    func testInvalidateMustBeCalledWhenIntervalEnded() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalEnded.notification)
        XCTAssertTrue(MockTimer.invalidateGotCalled,
                      "Invalidate must be called when IntervalEnded")
    }
    func testIntervalMustBeZeroAfterIntervalEnded() {
        generator.setInterval(timeInterval)
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalEnded.notification)
        XCTAssertEqual(generator.interval, 0.0,
                       "Interval must be 0 after IntervalEnded")
    }
    func testStatusButtonImageShouldChangeInImageChanged() {
        let oldImage = button.image
        sut.imageChanged(image: NSImage())
        XCTAssertNotEqual(oldImage, button.image,
                          "Button image should be changed")
    }
    func testDelegateOfGeneratorShouldNotBeNil() {
        XCTAssertNotNil(generator.delegate,
                        "Delegate must be setted")
        XCTAssertTrue(generator.delegate is RepeaterEventListener)
    }
    func testIncrementGotInvokedWithTimer() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        MockTimer.tick()
        XCTAssertTrue(generator.incrementGotCalled,
                      "Timer should increment interval")
    }
    func testPostIntervalMustBe0AfterIntervalStarted() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        XCTAssertEqual(generator.pastinterval, 0.0)
    }
    func testDelegateInIntervalStarted() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        XCTAssertTrue(delegate.intervalStartedGotCalled,
                      "Delegate should responce to IntervalStarted")
    }
    func testDelegateInIntervalStopped() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalStopped.notification)
        XCTAssertTrue(delegate.intervalStoppedGotCalled,
                      "Delegate should responce to IntervalStopped")
    }
    func testDelegateInIntervalResumed() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalResumed.notification)
        XCTAssertTrue(delegate.intervalResumedGotCalled,
                      "Delegate should responce to IntervalResumed")
    }
    func testDelegateInIntervalEnded() {
        nc.post(Notification.Name.IntervalReminderNotifications.IntervalEnded.notification)
        XCTAssertTrue(delegate.intervalEndedGotCalled,
                      "Delegate should responce to IntervalEnded")
    }
}
extension RepeaterEventListenerTests {
    class MockGenerator: ImageGeneratable {
        weak var delegate: ImageChangeListener?
        var generateGotInvoked = false
        func generate() -> NSImage {
            generateGotInvoked = true
            return NSImage()
        }
        var interval: Double?
        func setInterval(_ timeInterval: Double) {
            interval = timeInterval
        }
        var pastinterval: Double?
        func setPastInterval(_ timeInterval: Double){
            pastinterval = timeInterval
        }
        var incrementGotCalled = false
        func incrementInterval() {
            incrementGotCalled = true
        }
    }
    class MockNotificationCenter: NotificationCenterable {
        var mockNames: [NSNotification.Name] = []
        var mockObservers: [NSObjectProtocol] = []
        var mockNameToBlock: [NSNotification.Name: (Notification) -> Swift.Void] = [:]
        func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol {
            mockNames.append(name!)
            mockNameToBlock[name!] = block
            return getObserver()
        }
        private func getObserver() -> NSObject {
            let observer = NSObject()
            mockObservers.append(observer)
            return observer
        }
        func post(_ notification: Notification) {
            mockNameToBlock[notification.name]?(notification)
        }
        func removeObserver(_ observer: Any) {
            if let obs = observer as? NSObjectProtocol {
                deleteIfContained(obs)
            }
        }
        private func deleteIfContained(_ obs: NSObjectProtocol) {
            for index in 0..<mockObservers.count {
                if mockObservers[index].isEqual(obs) {
                    mockObservers.remove(at: index)
                    break
                }
            }
        }
    }
    class MockTimer: Timer {
        static var mockInterval: TimeInterval?
        static var mockRepeats = false
        static var mockBlock: ((Timer) -> Swift.Void)?
        override class func scheduledTimer(withTimeInterval interval: TimeInterval,
                                           repeats: Bool,
                                           block: @escaping (Timer) -> Swift.Void) -> Timer {
            mockRepeats = repeats
            mockInterval = interval
            mockBlock = block
            return MockTimer()
        }
        static var invalidateGotCalled = false
        override func invalidate() {
            MockTimer.invalidateGotCalled = true
        }
        static func tick() {
            mockBlock?(Timer())
        }
    }
    class MockDelegate: EventListenerDelegate {
        var intervalStartedGotCalled = false
        func intervalStarted() {
            intervalStartedGotCalled = true
        }
        var intervalStoppedGotCalled = false
        func intervalStopped() {
            intervalStoppedGotCalled = true
        }
        var intervalResumedGotCalled = false
        func intervalResumed() {
            intervalResumedGotCalled = true
        }
        var intervalEndedGotCalled = false
        func intervalEnded() {
            intervalEndedGotCalled = true
        }
    }
}
