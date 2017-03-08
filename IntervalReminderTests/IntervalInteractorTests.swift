import XCTest
@testable import IntervalReminder
class IntervalInteractorTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let testTick: Double = 34.5
    private let timerInterval: Double = 23.342
    private let timerText = "TestString3123213123"
    private var testInterval: Interval {
        return Interval(timerInterval, timerText)
    }
    private var secondTestInterval: Interval {
        return Interval(12.231, "Tst22")
    }
    
    // MARK: - Test variables
    private var sut: IntervalInteractor!
    private var presenter: MockPresenter!
    private var repeater: MockRepeater!
    private var timer: MockImmediateTimer!
    private var timerProvider: MockTimeProvider!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        presenter = MockPresenter()
        sut = IntervalInteractor(presenter)
        initFields()
        clearStatic()
    }
    private func initFields() {
        initRepeater()
        initScheduler()
        initTimeProvider()
    }
    private func initTimeProvider() {
        timerProvider = MockTimeProvider()
        sut.timeProvider = timerProvider
    }
    private func clearStatic() {
        MockImmediateTimer.mockInterval = nil
        MockImmediateTimer.mockRepeats = nil
        MockImmediateTimer.invalidateGotInvoked = false
        MockImmediateTimer.mockBlock = nil
    }
    private func initRepeater() {
        repeater = MockRepeater()
        sut.repeater = repeater
    }
    private func initScheduler() {
        timer = MockImmediateTimer()
        sut.timer = timer
    }
    override func tearDown() {
        sut = nil
        presenter = nil
        repeater = nil
        timer = nil
        timerProvider = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testCanBeCreated() {
        XCTAssertNotNil(sut)
    }
    func testRepeaterInitialized() {
        XCTAssertNotNil(sut.repeater)
    }
    func testCountMustBeProvidedByContainer() {
        sut.repeater.intervalContainer.add(testInterval)
        XCTAssertEqual(sut.count(), 1)
        sut.repeater.intervalContainer.add(secondTestInterval)
        XCTAssertEqual(sut.count(), 2)
    }
    func testTitleForRowMustBeFromAddedInterval() {
        sut.repeater.intervalContainer.add(testInterval)
        XCTAssertEqual(sut.title(forRow: 0), timerText)
    }
    func testIntervalForRowMustBeFromAddedInterval() {
        sut.repeater.intervalContainer.add(testInterval)
        XCTAssertEqual(sut.interval(forRow: 0), timerInterval)
    }
    func testCreateShouldAddIntervalToContainer() {
        sut.create(interval: timerInterval, withText: timerText)
        XCTAssertEqual(sut.interval(forRow: 0), timerInterval)
        XCTAssertEqual(sut.title(forRow: 0), timerText)
    }
    func testCreateMustInvokeDelegate() {
        sut.create(interval: timerInterval, withText: timerText)
        XCTAssertEqual(presenter.newIntervalIndex, 0)
        sut.create(interval: timerInterval, withText: timerText)
        XCTAssertEqual(presenter.newIntervalIndex, 0)
    }
    func testDeleteAt0MustRemoveFromIntervalContainer() {
        addTestIntervals()
        sut.delete(at: 0)
        XCTAssertEqual(sut.count(), 1)
        XCTAssertEqual(sut.title(forRow: 0), testInterval.text)
    }
    func testDeleteAt1MustRemoveFromIntervalContainer() {
        addTestIntervals()
        sut.delete(at: 1)
        XCTAssertEqual(sut.count(), 1)
        XCTAssertEqual(sut.title(forRow: 0), secondTestInterval.text)
    }
    private func addTestIntervals() {
        sut.repeater.intervalContainer.add(testInterval)
        sut.repeater.intervalContainer.add(secondTestInterval)
    }
    func testStartMustInvokeRepeaterStart() {
        sut.repeater.intervalContainer.add(testInterval)
        sut.start()
        XCTAssertTrue(repeater.startGotInvoked)
    }
    func testPauseMustInvokeRepeaterPause() {
        sut.pause()
        XCTAssertTrue(repeater.pauseGotInvoked)
    }
    func testResumeMustInvokeRepeaterResume() {
        sut.resume()
        XCTAssertTrue(repeater.resumeGotInvoked)
    }
    func testStopMustInvokeRepeaterStop() {
        sut.stop()
        XCTAssertTrue(repeater.stopGotInvoked)
    }
    func testPausedInitialStateMustBeFalse() {
        XCTAssertFalse(sut.paused)
    }
    func testIntervalActionMustInvokeStartIfNotInProgressNotPaused() {
        sut.repeater.intervalContainer.add(testInterval)
        sut.intervalAction()
        XCTAssertTrue(repeater.startGotInvoked)
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Pause.rawValue)
    }
    func testIntervalActionMustInvokeResumeIfInProgressPaused() {
        mockStart()
        sut.pause()
        sut.intervalAction()
        XCTAssertTrue(repeater.resumeGotInvoked)
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Pause.rawValue)
    }
    func testIntervalActionMustInvokePauseIfInProgressNotPaused() {
        mockStart()
        sut.intervalAction()
        XCTAssertTrue(repeater.pauseGotInvoked)
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Resume.rawValue)
    }
    private func mockStart() {
        sut.start()
        repeater.inProgress = true
    }
    func testPauseMustSetPaused() {
        sut.pause()
        XCTAssertTrue(sut.paused)
    }
    func testStartMustSetPausedToFalse() {
        sut.repeater.intervalContainer.add(testInterval)
        sut.pause()
        sut.start()
        XCTAssertFalse(sut.paused)
    }
    func testResumeMustSetPausedToFalse() {
        sut.pause()
        sut.resume()
        XCTAssertFalse(sut.paused)
    }
    func testStopMustSetPausedToFalse() {
        sut.pause()
        sut.stop()
        XCTAssertFalse(sut.paused)
    }
    func testProgressChangedMustConfigureStopButton() {
        sut.progressChanged(true)
        XCTAssertTrue(presenter.inProgress!)
    }
    func testCreateMustInvokeEnableButton() {
        sut.create(interval: timerInterval, withText: timerText)
        XCTAssertTrue(presenter.enableGotInvoked)
    }
    func testDeleteLastIntervalMustDisableButton() {
        sut.create(interval: timerInterval, withText: timerText)
        sut.create(interval: timerInterval, withText: timerText)
        sut.delete(at: 0)
        XCTAssertFalse(presenter.disableGotInvoked)
        sut.delete(at: 0)
        XCTAssertTrue(presenter.disableGotInvoked)
    }
    func testStartMustSetPauseTitle() {
        sut.repeater.intervalContainer.add(testInterval)
        sut.start()
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Pause.rawValue)
    }
    func testPauseMustSetResumeTitle() {
        sut.pause()
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Resume.rawValue)
    }
    func testResumeMustSetPauseTitle() {
        sut.resume()
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Pause.rawValue)
    }
    func testStopMustSetStartTitle() {
        sut.stop()
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Start.rawValue)
    }
    func testPregressChangeToFalseMustSetStartTitle() {
        sut.repeater.intervalContainer.add(testInterval)
        sut.start()
        sut.progressChanged(true)
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Pause.rawValue)
        sut.progressChanged(false)
        XCTAssertEqual(presenter.mockTitle, ButtonTitles.Start.rawValue)
    }
    func testTimerStartsInProgressChanged() {
        sut.progressChanged(true)
        XCTAssertEqual(MockImmediateTimer.mockInterval, 0.5)
    }
    func testTimerMustRepeat() {
        sut.progressChanged(true)
        XCTAssertEqual(MockImmediateTimer.mockRepeats, true)
    }
    func testCurrentTimerMustBeInitializedInProgressChange() {
        sut.progressChanged(true)
        XCTAssertNotNil(sut.currentProgressTimer)
    }
    func testCurrentTimerMustBeInvalidatedAfterProgressChangedToFalse() {
        sut.progressChanged(true)
        sut.progressChanged(false)
        XCTAssertTrue(MockImmediateTimer.invalidateGotInvoked)
        XCTAssertNil(sut.currentProgressTimer)
    }
    func testTimerMustInvokeUpdateProgressInPresenter() {
        sut.progressChanged(true)
        XCTAssertTrue(presenter.updateProgressGotInvoked)
        presenter.updateProgressGotInvoked = false
        MockImmediateTimer.mockBlock?(Timer())
        XCTAssertTrue(presenter.updateProgressGotInvoked)
    }
    func testChangeProgressToFalseMustUpdateProgress() {
        sut.progressChanged(false)
        XCTAssertTrue(presenter.updateProgressGotInvoked)
    }
    func testCurrentIndexMustBeEqualToRepeaterCurrentIndex() {
        XCTAssertEqual(sut.currentIndex, repeater.currentIndex)
    }
    func testCurrentTimeProviderMustBeInitialized() {
        XCTAssertNotNil(sut.timeProvider)
    }
    func testElapsedTimeMustReturnValidElapsedTime() {
        prepareTimeProvider()
        timerProvider.tick(testTick)
        XCTAssertEqual(sut.elapsedInterval(forRow: 0), testTick)
    }
    func testElapsedIntervalIfNotInProgressMustReturn0() {
        repeater.inProgress = false
        timerProvider.tick(testTick)
        XCTAssertEqual(sut.elapsedInterval(forRow: 0), 0)
    }
    func testElapsedTimeMustBeRelatedToRepeaterStartTime() {
        repeater.inProgress = true
        XCTAssertEqual(sut.elapsedInterval(forRow: 0), -repeater.currentStartTime)
    }
    func testPausedTimeCannotAffectToElapsedTime() {
        prepareTimeProvider()
        tickPauseTick()
        XCTAssertEqual(sut.elapsedInterval(forRow: 0), testTick)
    }
    private func tickPauseTick() {
        timerProvider.tick(testTick)
        sut.pause()
        repeater.currentStartTime = timerProvider.time
        timerProvider.tick(testTick)
    }
    private func prepareTimeProvider() {
        repeater.inProgress = true
        repeater.currentStartTime = 0.0
    }
    func testElapsedTimeAfterPause2Times() {
        tickPauseTickResumeTickPauseTick()
        XCTAssertEqual(sut.elapsedInterval(forRow: 0), 2 * testTick)
    }
    func testElapsedTimeMustBeValidAfterStop() {
        tickPauseTickResumeTickPauseTick()
        stopMock()
        tickPauseTick()
        XCTAssertEqual(sut.elapsedInterval(forRow: 0), testTick)
    }
    private func stopMock() {
        sut.stop()
        repeater.currentStartTime = timerProvider.time
    }
    private func tickPauseTickResumeTickPauseTick() {
        prepareTimeProvider()
        tickPauseTick()
        sut.resume()
        repeater.currentStartTime = timerProvider.time
        tickPauseTick()
    }
    func testElapsedTimeMustBeValidAfterIntervalDidEnd() {
        tickPauseTickResumeTickPauseTick()
        sut.intervalDidEnd(text: "", at: 0)
        repeater.currentStartTime = timerProvider.time
        tickPauseTick()
        XCTAssertEqual(sut.elapsedInterval(forRow: 0), testTick)
    }
    func testElapsedTimeMustBeValidAfterProgressChanged() {
        tickPauseTickResumeTickPauseTick()
        sut.progressChanged(true)
        repeater.currentStartTime = timerProvider.time
        tickPauseTick()
        XCTAssertEqual(sut.elapsedInterval(forRow: 0), testTick)
    }
    func testIntervalDidStartInvokePresentersIntervalStarted() {
        sut.create(interval: timerInterval, withText: timerText)
        sut.intervalDidStart(at: 0)
        XCTAssertEqual(presenter.startInterval, timerInterval)
    }
    func testStopMustInvokePresentersIntervalEnded() {
        sut.stop()
        XCTAssertTrue(presenter.intervalEndedGotInvoked)
    }
    func testChangeProgressToFalseMustInvokePresentersIntervalEnded() {
        sut.progressChanged(true)
        XCTAssertFalse(presenter.intervalEndedGotInvoked)
        sut.progressChanged(false)
        XCTAssertTrue(presenter.intervalEndedGotInvoked)
    }
    func testPauseMustInvokePresentersIntervalStopped() {
        sut.pause()
        XCTAssertTrue(presenter.intervalStoppedGotInvoked)
    }
    func testResumeMustInvokePresentersIntervalResumed() {
        sut.create(interval: timerInterval, withText: timerText)
        repeater.currentIndex = 0
        sut.resume()
        XCTAssertNotNil(presenter.elapsedInterval)
        XCTAssertNotNil(presenter.fullInterval)
    }
    func testIntervalResumedMustBeWithValidParameters() {
        pauseAndResume()
        XCTAssertEqual(presenter.elapsedInterval, 0.1)
        XCTAssertEqual(presenter.fullInterval, timerInterval)
    }
    private func pauseAndResume() {
        sut.create(interval: timerInterval, withText: timerText)
        repeater.currentIndex = 0
        prepareTimeProvider()
        sut.start()
        timerProvider.tick()
        sut.pause()
        sut.resume()
    }
    func testStartWithEmptyContainerMustBeIgnored() {
        sut.start()
        XCTAssertFalse(repeater.startGotInvoked)
    }
    func testIntervalDidEndMustInvokePresentersIntervalEnded() {
        sut.intervalDidEnd(text: "", at: 0)
        XCTAssertTrue(presenter.intervalEndedGotInvoked)
    }
    func testChangeRepeatMustChangeRepeatFieldOfRepeater() {
        sut.changeRepeat()
        XCTAssertTrue(repeater.repeatIntervals)
        sut.changeRepeat()
        XCTAssertFalse(repeater.repeatIntervals)
    }
    func testNotificationPresenterMustBeNotNil() {
        XCTAssertNotNil(sut.notificationPresenter)
    }
    func testIntervalDidEndMustInvokeNotification() {
        let np = MockNotificationPresenter()
        sut.notificationPresenter = np
        sut.intervalDidEnd(text: timerText , at: 0)
        XCTAssertEqual(np.nTitle, timerText)
    }
}
extension IntervalInteractorTests {
    class MockNotificationPresenter: NotificationPresenterProtocol {
        var nTitle: String?
        func presentNotification(_ title: String) {
            nTitle = title
        }
    }
    class MockPresenter: IntervalPresenterProtocol, IntervalsChangePresenter {
        func count() -> Int {
            return 0
        }
        func present(cell: NSTableCellView, at row: Int) {
        }
        var newIntervalIndex: Int?
        func newInterval(at index: Int) {
            newIntervalIndex = index
        }
        var enableGotInvoked = false
        func enableIntervalButton() {
            enableGotInvoked = true
        }
        var disableGotInvoked = false
        func disableIntervalButton() {
            disableGotInvoked = true
        }
        var inProgress: Bool?
        func configureStopButton(inProgress: Bool) {
            self.inProgress = inProgress
        }
        var mockTitle: String?
        func configureIntervalButton(title: String) {
            mockTitle = title
        }
        var updateProgressGotInvoked = false
        func updateProgress() {
            updateProgressGotInvoked = true
        }
        var startInterval: Double?
        func intervalStarted(_ interval: Double) {
            startInterval = interval
        }
        var intervalStoppedGotInvoked = false
        func intervalStopped() {
            intervalStoppedGotInvoked = true
        }
        var intervalEndedGotInvoked = false
        func intervalEnded() {
            intervalEndedGotInvoked = true
        }
        var elapsedInterval: Double?
        var fullInterval: Double?
        func intervalResumed(elapsed: Double, interval: Double) {
            elapsedInterval = elapsed
            fullInterval = interval
        }
    }
    class MockRepeater: ContainerListener, IntervalRepeaterProtocol {
        private(set) var intervalContainer: IntervalContainer!
        var currentStartTime: Double = 34.0
        var repeatIntervals = false
        var inProgress: Bool = false
        var startGotInvoked = false
        var currentIndex: Int = 100
        func start() {
            startGotInvoked = true
        }
        var resumeGotInvoked = false
        func resume() {
            resumeGotInvoked = true
        }
        var stopGotInvoked = false
        func stop() {
            stopGotInvoked = true
        }
        var pauseGotInvoked = false
        func pause(){
            pauseGotInvoked = true
        }
        init() {
            intervalContainer = IntervalContainer(self)
        }
        func itemAdded() {
        }
        func itemRemoved(at index: Int) {
        }
        func itemMoved(from fromIndex: Int, to toIndex: Int) {
        }
    }
    class MockImmediateTimer: Timer {
        static var mockInterval: TimeInterval?
        static var mockRepeats: Bool?
        static var mockBlock: ((Timer) -> Swift.Void)?
        override class func scheduledTimer(withTimeInterval interval: TimeInterval,
                                           repeats: Bool,
                                           block: @escaping (Timer) -> Swift.Void) -> Timer {
            let moc = MockImmediateTimer()
            MockImmediateTimer.mockInterval = interval
            MockImmediateTimer.mockRepeats = repeats
            block(moc)
            mockBlock = block
            return moc
        }
        static var invalidateGotInvoked = false
        override func invalidate() {
            MockImmediateTimer.invalidateGotInvoked = true
        }
    }
}
