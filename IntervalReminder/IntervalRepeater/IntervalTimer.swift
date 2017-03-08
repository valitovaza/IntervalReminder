import Foundation
import QuartzCore

protocol TimeScheduler {
    static func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Swift.Void) -> Timer
}
extension Timer: TimeScheduler {}
extension TimeScheduler {
    func scheduledTimer(withTimeInterval interval: TimeInterval,
                        repeats: Bool,
                        block: @escaping (Timer) -> Swift.Void) -> Timer {
        return Self.scheduledTimer(withTimeInterval: interval,
                                   repeats: repeats,
                                   block: block)
    }
}
protocol CurrentTimeProvider {
    func currentTime() -> Double
}
struct CATimeProvider: CurrentTimeProvider {
    func currentTime() -> Double {
        return CACurrentMediaTime()
    }
}
protocol ResumableTimer {
    var startTime: Double {get}
    func scheduleInterval(_ interval: Double,
                          block: @escaping ()->())
    func stop()
    func resume()
}
class IntervalTimer: ResumableTimer {
    enum State {
        case Idle
        case InProgress
        case Stopped
    }
    private(set) var state: State
    private var timer: Timer?
    private var timeScheduler: TimeScheduler!
    private var timeProvider: CurrentTimeProvider!

    private(set) var startTime: Double = 0.0
    private var remainedInterval: Double = 0.0
    private var currentInterval: Double = 0.0
    
    init(_ timeScheduler: TimeScheduler = Timer(),
         _ timeProvider: CurrentTimeProvider = CATimeProvider()) {
        state = .Idle
        self.timeScheduler = timeScheduler
        self.timeProvider = timeProvider
    }
    private var currentBlock: (()->())? = nil
    func scheduleInterval(_ interval: Double,
                          block: @escaping () -> ()) {
        checkPreviousState()
        state = .InProgress
        currentBlock = block
        createTimer(interval)
    }
    private func createTimer(_ interval: Double) {
        setCurrentInterval(interval)
        timer = timeScheduler.scheduledTimer(withTimeInterval: interval,
                                     repeats: false,
                                     block: {[weak self] (_) in
            self?.state = .Idle
            self?.currentBlock?()
        })
    }
    private func setCurrentInterval(_ interval: Double) {
        startTime = timeProvider.currentTime()
        currentInterval = interval
    }
    private func checkPreviousState() {
        if state == .InProgress {
            executeBlock()
        }
    }
    private func executeBlock() {
        if let currentBlock = currentBlock {
            currentBlock()
        }
    }
    func stop() {
        invalidateTimer()
        setStopped()
    }
    private func saveRemainedInterval() {
        let elapsedTime = timeProvider.currentTime() - startTime
        remainedInterval = currentInterval - elapsedTime
    }
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    private func setStopped() {
        if state == .InProgress {
            state = .Stopped
            saveRemainedInterval()
        }
    }
    func resume() {
        if state == .Stopped {
            state = .InProgress
            createTimer(remainedInterval)
        }
    }
}
