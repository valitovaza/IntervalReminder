import XCTest
@testable import IntervalReminder
class IntervalTimerTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let interval: TimeInterval = 3.453
    private let timerRepeats = true
    
    // MARK: - Test variables
    private var sut: IntervalTimer!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        sut = IntervalTimer()
        clearFlags()
    }
    private func clearFlags() {
        MockImmediateTimer.mockInterval = nil
        MockImmediateTimer.mockRepeats = nil
        MockTimer.invalidateGotCalled = nil
        MockTimer.scheduleGotCalled = nil
        MockTimer.mockInterval = nil
        MockTimer.scheduledCount = nil
    }
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testInitialProgressState() {
        XCTAssertEqual(sut.state, .Idle,
                       "Initial state must be Idle")
    }
    func testScheduleIntervalShouldChangeState() {
        sut.scheduleInterval(0.0) {}
        XCTAssertEqual(sut.state, .InProgress,
                       "Schedule method must change status to InProgress")
    }
    func testStopShouldBeIgnoredIfIdleState() {
        sut.stop()
        XCTAssertEqual(sut.state, .Idle,
                       "stop() is ignored if state is Idle")
    }
    func testStopMustSetStateToStopped() {
        sut.scheduleInterval(0.0) {}
        sut.stop()
        XCTAssertEqual(sut.state, .Stopped,
                       "Stopped state expected after stop()")
    }
    func testResumeShouldBeIgnoredIfIdleState() {
        sut.resume()
        XCTAssertEqual(sut.state, .Idle,
                       "resume() is ignored if state is not Stopped")
    }
    func testResumeShouldChangeStateToInProgress() {
        sut.scheduleInterval(0.0) {}
        sut.stop()
        sut.resume()
        XCTAssertEqual(sut.state, .InProgress,
                       "Resume method must change status to InProgress")
    }
    func testBlockMustNotBeCalledImmediately() {
        var blockGotCalled = false
        sut.scheduleInterval(3.0) {
            blockGotCalled = true
        }
        XCTAssertFalse(blockGotCalled,
                       "ScheduleInterval should not perform block immediately")
    }
    func testPreviousScheduleBlockMustBeImmediatelyCalledAfterNextOne() {
        var blockGotCalled = false
        sut.scheduleInterval(3.0) { 
            blockGotCalled = true
        }
        sut.scheduleInterval(2.0) {}
        XCTAssertTrue(blockGotCalled, "ScheduleInterval should perform previous block immediately if state InProgress")
    }
    func testBlockGotCalledAfterInterval() {
        var blockGotCalled = false
        let sut = getImmediateTimerWithMockTimer()
        sut.scheduleInterval(interval, block: {blockGotCalled = true})
        XCTAssertTrue(blockGotCalled,
                      "Block must be called after schedule")
    }
    func testBlockExecutionIntervalEqualToProvided() {
        let sut = getImmediateTimerWithMockTimer()
        sut.scheduleInterval(interval, block: {})
        XCTAssertEqual(MockImmediateTimer.mockInterval, interval,
                       "Interval must be equal to provided")
    }
    func testStateAfterBlockExecutionMustBeIdle() {
        let sut = getImmediateTimerWithMockTimer()
        sut.scheduleInterval(interval, block: {})
        XCTAssertEqual(sut.state, .Idle,
                       "State should be Idle after timer")
    }
    func testBlockShouldNotRepeat() {
        let sut = getImmediateTimerWithMockTimer()
        sut.scheduleInterval(interval, block: {})
        XCTAssertFalse(MockImmediateTimer.mockRepeats!,
                       "Block should not repeat")
    }
    private func getImmediateTimerWithMockTimer() -> IntervalTimer {
        let mockTimer = MockImmediateTimer()
        let sut = IntervalTimer(mockTimer)
        return sut
    }
    func testInvalidateCalledWhenStop() {
        let sut = IntervalTimer(MockTimer())
        scheduleAndStop(sut)
        XCTAssertTrue(MockTimer.invalidateGotCalled!,
                      "Invalidate got called after stop")
    }
    private func scheduleAndStop(_ sut: IntervalTimer) {
        sut.scheduleInterval(0.3, block: {})
        sut.stop()
    }
    func testResumeMustContinueTimer() {
        let sut = IntervalTimer(MockTimer())
        scheduleStopAndResume(sut)
        XCTAssertNotNil(MockTimer.scheduleGotCalled,
                        "ScheduledTimer must be called after resume")
    }
    private func scheduleStopAndResume(_ sut: IntervalTimer) {
        scheduleAndStop(sut)
        MockTimer.scheduleGotCalled = nil
        sut.resume()
    }
    func testScheduledTimerMustNotCalledIfBlockAlreadyCalled() {
        let sut = getImmediateTimerWithMockTimer()
        scheduleAndResume(sut)
        XCTAssertNil(MockImmediateTimer.mockRepeats,
                     "ScheduledTimer must not be called after resume if block already called")
    }
    private func scheduleAndResume(_ sut: IntervalTimer) {
        sut.scheduleInterval(interval, block: {})
        MockImmediateTimer.mockRepeats = nil
        sut.resume()
    }
    func testResumeMustScheduleTimerWithRemainedIntervals() {
        let timeEmulator = MockTimeProvider()
        let sut = IntervalTimer(MockTimer(), timeEmulator)
        scheduleAndEmulateTime(sut, timeEmulator)
        sut.stop()
        sut.resume()
        XCTAssertEqual(MockTimer.mockInterval, interval - 0.2,
                       "ScheduledTimer must be called with remained time period")
    }
    private func scheduleAndEmulateTime(_ sut: IntervalTimer,
                                        _ timer: MockTimeProvider) {
        sut.scheduleInterval(interval, block: {})
        perormTiks(timer)
    }
    func testStoppedBlockMustNotBeCalledAfterNextSchedule() {
        let sut = IntervalTimer(MockTimer())
        schedule2TimesWithStop(sut)
        XCTAssertEqual(MockTimer.scheduledCount, 1,
                       "Must be called only last block")
    }
    private func schedule2TimesWithStop(_ sut: IntervalTimer) {
        sut.scheduleInterval(0.0, block: {})
        sut.stop()
        MockTimer.scheduledCount = nil
        sut.scheduleInterval(0.0, block: {})
    }
    func testOnlyFirstStopShouldChangeRemainedInterval() {
        let timeEmulator = MockTimeProvider()
        let sut = IntervalTimer(MockTimer(), timeEmulator)
        scheduleAndEmulateTime(sut, timeEmulator)
        emulate2StopsAndResume(sut, timeEmulator)
        XCTAssertEqual(MockTimer.mockInterval, interval - 0.2,
                       "Only first stop can change remained time")
    }
    private func emulate2StopsAndResume(_ sut: IntervalTimer,
                                        _ timer: MockTimeProvider) {
        sut.stop()
        perormTiks(timer)
        sut.stop()
        sut.resume()
    }
    private func perormTiks(_ timer: MockTimeProvider) {
        timer.tick()
        timer.tick()
    }
    
    // MARK: - Timer extension tests
    func testTimerScheduledCalledWithProvidedParameters() {
        var blockGotCalled = false
        let block: (Timer) -> Swift.Void = {_ in blockGotCalled = true}
        _ = MockImmediateTimer().scheduledTimer(withTimeInterval: interval,
                                       repeats: timerRepeats,
                                       block: block)
        XCTAssertEqual(MockImmediateTimer.mockInterval, interval,
                       "Interval equal to provided")
        XCTAssertEqual(MockImmediateTimer.mockRepeats, timerRepeats,
                       "Block must not repeat")
        XCTAssertTrue(blockGotCalled,
                      "Block should be called")
    }
}
extension IntervalTimerTests {
    // MARK: - Mocks
    class MockImmediateTimer: Timer {
        static var mockInterval: TimeInterval?
        static var mockRepeats: Bool?
        override class func scheduledTimer(withTimeInterval interval: TimeInterval,
                                           repeats: Bool,
                                           block: @escaping (Timer) -> Swift.Void) -> Timer {
            let moc = MockImmediateTimer()
            MockImmediateTimer.mockInterval = interval
            MockImmediateTimer.mockRepeats = repeats
            block(moc)
            return moc
        }
    }
    class MockTimer: Timer {
        static var scheduleGotCalled: Bool?
        static var mockInterval: TimeInterval?
        static var scheduledCount: Int?
        override class func scheduledTimer(withTimeInterval interval: TimeInterval,
                                           repeats: Bool,
                                           block: @escaping (Timer) -> Swift.Void) -> Timer {
            incrementCount()
            scheduleGotCalled = true
            mockInterval = interval
            return MockTimer()
        }
        private static func incrementCount() {
            if let scheduledCount = scheduledCount {
                MockTimer.scheduledCount = scheduledCount + 1
            }else{
                MockTimer.scheduledCount = 1
            }
        }
        static var invalidateGotCalled: Bool?
        override func invalidate() {
            MockTimer.invalidateGotCalled = true
        }
    }
}
