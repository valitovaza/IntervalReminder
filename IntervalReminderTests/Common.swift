@testable import IntervalReminder
class MockTimeProvider: CurrentTimeProvider {
    var time: Double = 0.0
    func currentTime() -> Double {
        return time
    }
    func tick(_ interval: Double = 0.1) {
        time += interval
    }
}
