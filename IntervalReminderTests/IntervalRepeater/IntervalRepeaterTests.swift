import XCTest
@testable import IntervalReminder
class IntervalRepeaterTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let timeInterval: Double = 1.3241
    private let timeText = "TestString214414"
    private var testInterval: Interval {
        return Interval(timeInterval, timeText)
    }
    private var testInterval0: Interval {
        return Interval(0.12, "0")
    }
    private var testInterval1: Interval {
        return Interval(0.2, "1")
    }
    private var testInterval2: Interval {
        return Interval(0.104, "2")
    }
    
    // MARK: - Test variables
    private var sut: IntervalRepeater!
    private var delegate: MockRepeaterDelegate!
    private var mockTimer: MockTimer!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        initiateVariables()
    }
    private func initiateVariables() {
        delegate = MockRepeaterDelegate()
        mockTimer = MockTimer()
        sut = IntervalRepeater(delegate, mockTimer)
    }
    override func tearDown() {
        clearVariables()
        super.tearDown()
    }
    private func clearVariables() {
        sut = nil
        delegate = nil
        mockTimer = nil
    }
    
    // MARK: - Tests
    func testRepeaterContainsIntervalContainer() {
        XCTAssertNotNil(sut.intervalContainer,
                        "Repeater must contain intervalContainer")
    }
    func testRepeaterRepeatField() {
        XCTAssertEqual(sut.repeatIntervals, false,
                       "Initial repeatIntervals = false")
    }
    func testCanSwitchRepeatField() {
        sut.repeatIntervals = true
        XCTAssertEqual(sut.repeatIntervals, true,
                       "RepeatIntervals can be changed")
    }
    func testInitialCurrentIndex() {
        XCTAssertEqual(sut.currentIndex, 0,
                       "Initial current index = 0")
    }
    func testCanStartWithoutIntervals() {
        sut.start()
        XCTAssertEqual(sut.currentIndex, 0,
                       "Start without intervals do nothing")
    }
    func testDelegateReceiveProperText() {
        sut.intervalContainer.add(testInterval)
        sut.start()
        XCTAssertEqual(delegate.endText, timeText,
                       "Delegate must receive last scheduled interval text")
    }
    func testTimerInterval() {
        sut.intervalContainer.add(testInterval)
        sut.start()
        XCTAssertEqual(mockTimer.interval, testInterval.timeInterval,
                       "Timer interval must be set from the provided data")
    }
    func testIntervalsQueue() {
        let delegate = MockDelegateWithCache()
        let sut = IntervalRepeater(delegate, mockTimer)
        startWith3TestIntervals(sut)
        verifyQueueResults(delegate)
    }
    private func startWith3TestIntervals(_ sut: IntervalRepeater) {
        add3TestIntervals(to: sut)
        sut.start()
    }
    private func verifyQueueResults(_ delegate: MockDelegateWithCache) {
        XCTAssertEqual(delegate.endTexts,
                       [testInterval0.text,
                        testInterval1.text, testInterval2.text],
                       "All intervals should be passed")
        XCTAssertEqual(delegate.currentIndexes,
                       [0, 1, 2],
                       "Current indexes should change")
    }
    private func add3TestIntervals(to sut: IntervalRepeater) {
        sut.intervalContainer.add(testInterval2)
        sut.intervalContainer.add(testInterval1)
        sut.intervalContainer.add(testInterval0)
    }
    func testCurrentIntervalAtTheEnd() {
        add3TestIntervals(to: sut)
        sut.start()
        XCTAssertEqual(sut.currentIndex, 0,
                       "Current index at the ent must be 0")
    }
    func testNotRepeatCase() {
        let delegate = MockDelegateWithCache()
        let sut = IntervalRepeater(delegate, mockTimer)
        startWith3TestIntervals(sut)
        XCTAssertEqual(delegate.endTexts.count, 3)
    }
    func testRepeatCase() {
        let restrictedTimer = MockRestrictedTimer()
        let sut = IntervalRepeater(delegate, restrictedTimer)
        startRepeatCase(sut)
        XCTAssertEqual(restrictedTimer.timesCount, restrictedTimer.maxTimes,
                       "Repeater must work till maxTimes reached")
    }
    private func startRepeatCase(_ sut: IntervalRepeater) {
        sut.repeatIntervals = true
        add3TestIntervals(to: sut)
        sut.start()
    }
    func testCurrentIndexAfterDeleteIntervalAtThatIndex() {
        let sut = repeaterWithCurrentIndex(index: 2).sut
        sut.intervalContainer.remove(at: 2)
        XCTAssertEqual(sut.currentIndex, 1)
    }
    private func repeaterWithCurrentIndex(index: Int) -> (sut: IntervalRepeater, timer: MockRestrictedTimer) {
        let restrictedTimer = MockRestrictedTimer()
        let sut = IntervalRepeater(delegate, restrictedTimer)
        addIntervalsAndSchedule(sut, restrictedTimer, maxTimes: index)
        XCTAssertEqual(sut.currentIndex, index,
                       "Current index must be \(index)")
        return (sut: sut, timer: restrictedTimer)
    }
    private func addIntervalsAndSchedule(_ sut: IntervalRepeater,
                                          _ restrictedTimer: MockRestrictedTimer, maxTimes: Int) {
        restrictedTimer.maxTimes = maxTimes
        while sut.intervalContainer.intervalsCount < maxTimes {
            add3TestIntervals(to: sut)
        }
        sut.start()
    }
    func testCurrentIndexAfterRemoveAtEmpty() {
        sut.intervalContainer.remove(at: 0)
        XCTAssertEqual(sut.currentIndex, 0,
                       "Current index don't change if invalid remove index")
    }
    func testCurrentIndexWhenRemoveAtInvalidIndex() {
        sut.intervalContainer.remove(at: -11)
        XCTAssertEqual(sut.currentIndex, 0,
                       "Current index don't change if invalid remove index")
        sut.intervalContainer.remove(at: 11)
        XCTAssertEqual(sut.currentIndex, 0,
                       "Current index don't change if invalid remove index")
    }
    func testCurrentIndexAfterRemoveAtIndexAbove() {
        let sut = repeaterWithCurrentIndex(index: 10).sut
        XCTAssertEqual(sut.currentIndex, 10)
        sut.intervalContainer.remove(at: 3)
        XCTAssertEqual(sut.currentIndex, 9,
                       "Current index must decrement if interval above current index delete")
    }
    func testCurrentIndexAfterRemoveAtIndexBelow() {
        let sut = repeaterWithCurrentIndex(index: 1).sut
        XCTAssertEqual(sut.currentIndex, 1)
        sut.intervalContainer.remove(at: 2)
        XCTAssertEqual(sut.currentIndex, 1,
                       "Current index don't change if interval below current index delete")
    }
    func testAfterDeleteIntervalAtCurrentIndexStopShouldBeCalled() {
        let repeater = repeaterWithCurrentIndex(index: 2)
        let sut = repeater.sut
        let timer = repeater.timer
        sut.intervalContainer.remove(at: 2)
        XCTAssertTrue(timer.stopGotCalled,
                      "Stop should be called if remove current interval")
    }
    func testAfterDeleteIntervalAboveCurrentIndexStopShouldNotBeCalled() {
        let repeater = repeaterWithCurrentIndex(index: 10)
        let sut = repeater.sut
        let timer = repeater.timer
        sut.intervalContainer.remove(at: 3)
        XCTAssertFalse(timer.stopGotCalled,
                      "Stop should not be called if remove not in current interval")
    }
    func testAddNewIntervalShouldNotChangeInitialCurrentIndex() {
        sut.intervalContainer.add(testInterval)
        XCTAssertEqual(sut.currentIndex, 0,
                       "Initial current index should not be changed after add new interval")
    }
    func testAddNewIntervalShouldChangeCurrentIndexIfAnyIntervalStarted() {
        sut.start()
        sut.intervalContainer.add(testInterval)
        sut.intervalContainer.add(testInterval)
        XCTAssertEqual(sut.currentIndex, 1,
                       "Add new interval should change current index if any interval started")
    }
    func testAddNewIntervalShouldChangeCurrentIndexAfterSetIndexManually() {
        sut.setCurrentIndex(0)
        sut.intervalContainer.add(testInterval)
        sut.intervalContainer.add(testInterval)
        XCTAssertEqual(sut.currentIndex, 1,
                       "Add new interval should change current after set current index manyally")
    }
    func testSetCurrentIndexMustChangeCurrentIndex() {
        add2TestIntervals(sut)
        sut.setCurrentIndex(1)
        XCTAssertEqual(sut.currentIndex, 1,
                       "Current index should be changed to provided")
    }
    func testSetCurrentIndexCantChangeIndexIfInvalidIndexProvided() {
        sut.setCurrentIndex(-1)
        XCTAssertEqual(sut.currentIndex, 0,
                       "Current index should not be changed if invalid index")
        sut.setCurrentIndex(1)
        XCTAssertEqual(sut.currentIndex, 0,
                       "Current index should not be changed if invalid index")
    }
    func testItemMovedShouldChangeCurrentIndex() {
        add2TestIntervals(sut)
        sut.intervalContainer.move(from: 0, to: 1)
        XCTAssertEqual(sut.currentIndex, 1,
                       "Item moved should change current index")
    }
    private func add2TestIntervals(_ sut: IntervalRepeater) {
        sut.intervalContainer.add(testInterval0)
        sut.intervalContainer.add(testInterval1)
    }
    func testItemMoveShouldNotAffectToCurrentIndexIfFromIndexNotEqualToCurrent() {
        add3TestIntervals(to: sut)
        sut.intervalContainer.move(from: 1, to: 2)
        XCTAssertEqual(sut.currentIndex, 0,
                       "Item moved should not change current index if from index != current")
    }
    func testRemoveLastItemMustNotChangeCurrentIndex() {
        sut.intervalContainer.add(testInterval)
        sut.intervalContainer.remove(at: 0)
        XCTAssertEqual(sut.currentIndex, 0,
                       "Remove last item must not change current index")
    }
    func testPauseMustInvokeTimerStop() {
        sut.pause()
        XCTAssertTrue(mockTimer.stopGotInvoked)
    }
    func testStopMustSetIntervalTo0() {
        add2TestIntervals(sut)
        sut.setCurrentIndex(1)
        sut.stop()
        XCTAssertEqual(sut.currentIndex, 0)
    }
    func testProgressInitStateIsFalse() {
        XCTAssertFalse(sut.inProgress)
    }
    func testStartMustNotChangeProgressIfEmptyContainer() {
        sut.start()
        XCTAssertFalse(sut.inProgress)
    }
    func testStartMustSetProgressIfNotEmpty() {
        let sut = inProgressRepeater()
        XCTAssertTrue(sut.inProgress)
    }
    private func startedRepeaterWith3Intervals(timer: MockRestrictedTimer) -> IntervalRepeater {
        let sut = IntervalRepeater(delegate, timer)
        add3TestIntervals(to: sut)
        sut.start()
        return sut
    }
    func testPauseMustNotChangeProgress() {
        sut.pause()
        XCTAssertFalse(sut.inProgress)
        let inProgressSut = inProgressRepeater()
        inProgressSut.pause()
        XCTAssertTrue(inProgressSut.inProgress)
    }
    private func inProgressRepeater() -> IntervalRepeater {
        let restrictedTimer = MockRestrictedTimer()
        restrictedTimer.maxTimes = 0
        let sut = startedRepeaterWith3Intervals(timer: restrictedTimer)
        return sut
    }
    func testResumeMustNotChangeProgress() {
        sut.resume()
        XCTAssertFalse(sut.inProgress)
        let inProgressSut = inProgressRepeater()
        inProgressSut.resume()
        XCTAssertTrue(inProgressSut.inProgress)
    }
    func testStopMustSetProgressToFalse() {
        let inProgressSut = inProgressRepeater()
        inProgressSut.stop()
        XCTAssertFalse(inProgressSut.inProgress)
    }
    func testStopMustStopScheduler() {
        sut.stop()
        XCTAssertTrue(mockTimer.stopGotInvoked)
    }
    func testIfLastIntervalEndedInProgressMustBeFalse() {
        add3TestIntervals(to: sut)
        sut.start()
        XCTAssertFalse(sut.inProgress)
    }
    func testInProgressChangeMustCallDelegate() {
        add3TestIntervals(to: sut)
        sut.start()
        XCTAssertEqual(delegate.progresses.count, 2)
    }
    func testInProgressMustChangeOnlyOnceWhenStart() {
        _ = repeaterWithCurrentIndex(index: 10)
        XCTAssertEqual(delegate.progresses.count, 1)
    }
    func testRemoveCurrentIntervalMustChangeInProgress() {
        let inProgressSut = inProgressRepeater()
        XCTAssertTrue(inProgressSut.inProgress)
        inProgressSut.intervalContainer.remove(at: 0)
        XCTAssertFalse(inProgressSut.inProgress)
    }
    func testResumeMustNotCallSchedulersResumeIfNotInProgress() {
        sut.resume()
        XCTAssertFalse(mockTimer.resumeGotInvoked)
    }
    func testResumeMustInvokeTimerResumeIfInProgress() {
        let restrictedTimer = MockRestrictedTimer()
        restrictedTimer.maxTimes = 0
        let sut = startedRepeaterWith3Intervals(timer: restrictedTimer)
        sut.resume()
        XCTAssertTrue(restrictedTimer.resumeGotInvoked)
    }
    func testStartMustInvokeIntervalDidStartIfValidCurrentIndex() {
        sut.start()
        XCTAssertNil(delegate.startIndex)
        sut.intervalContainer.add(testInterval)
        sut.setCurrentIndex(0)
        sut.start()
        XCTAssertEqual(delegate.startIndex, 0)
    }
    func testCurrentStartTimeMustBeProvidedFromScheduler() {
        XCTAssertEqual(sut.currentStartTime, mockTimer.startTime)
    }
    func testItemAddedMustNotSetInvalidCurrentIndex() {
        sut.start()
        sut.intervalContainer.add(testInterval)
        XCTAssertEqual(sut.currentIndex, 0)
    }
}
extension IntervalRepeaterTests {
    // MARK: - Mocks
    class MockRepeaterDelegate: RepeaterDelegate {
        var startIndex: Int?
        func intervalDidStart(at index: Int) {
            startIndex = index
        }
        var endText: String? = nil
        func intervalDidEnd(text: String, at index: Int) {
            endText = text
        }
        var progresses: [Bool] = []
        func progressChanged(_ progress: Bool) {
            progresses.append(progress)
        }
    }
    class MockDelegateWithCache: RepeaterDelegate {
        var endTexts: [String] = []
        var currentIndexes: [Int] = []
        func intervalDidStart(at index: Int) {
        }
        func intervalDidEnd(text: String, at index: Int) {
            currentIndexes.append(index)
            endTexts.append(text)
        }
        func progressChanged(_ progress: Bool) {}
    }
    class MockTimer: ResumableTimer {
        private(set) var interval: TimeInterval = -1130.0
        var startTime: Double = 45.0
        func scheduleInterval(_ interval: Double,
                              block: @escaping () -> ()) {
            self.interval = interval
            block()
        }
        var stopGotInvoked = false
        func stop() {
            stopGotInvoked = true
        }
        var resumeGotInvoked = false
        func resume(){
            resumeGotInvoked = true
        }
    }
    class MockRestrictedTimer: ResumableTimer {
        var startTime: Double = 0.0
        private(set) var timesCount = 0
        var maxTimes = 10
        func scheduleInterval(_ interval: Double,
                              block: @escaping () -> ()) {
            if timesCount < maxTimes {
                timesCount += 1
                block()
            }
        }
        private(set) var stopGotCalled = false
        func stop() {
            stopGotCalled = true
        }
        var resumeGotInvoked = false
        func resume() {
            resumeGotInvoked = true
        }
    }
}
