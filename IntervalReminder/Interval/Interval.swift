struct Interval {
    let timeInterval: Double
    let text: String
    init(_ timeInterval: Double, _ text: String) {
        self.timeInterval = timeInterval
        self.text = text
    }
}

// MARK: - Equatable
extension Interval: Equatable {}
func ==(lhs: Interval, rhs: Interval) -> Bool {
    if lhs.timeInterval != rhs.timeInterval { return false }
    if lhs.text != rhs.text { return false }
    return true
}
