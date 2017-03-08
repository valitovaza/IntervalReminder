protocol ContainerListener: class {
    func itemAdded()
    func itemRemoved(at index: Int)
    func itemMoved(from fromIndex: Int, to toIndex: Int)
}
class IntervalContainer {
    var intervalsCount: Int {
        return intervals.count
    }
    private var intervals: [Interval] = []
    private weak var listener: ContainerListener?
    init(_ listener: ContainerListener? = nil) {
        self.listener = listener
    }
    func add(_ interval: Interval) {
        intervals.insert(interval, at: 0)
        listener?.itemAdded()
    }
    func remove(at index: Int) {
        if isValidIndex(index) {
            removeItem(at: index)
        }
    }
    private func removeItem(at index: Int) {
        intervals.remove(at: index)
        listener?.itemRemoved(at: index)
    }
    private func isValidIndex(_ index: Int) -> Bool {
        return index >= 0 && intervals.count > index
    }
    func interval(at index: Int) -> Interval? {
        return isValidIndex(index) ? intervals[index] : nil
    }
    func move(from fromIndex: Int, to toIndex: Int) {
        if let fromInterval = interval(at: fromIndex),
            isValidMoveIndexes(from: fromIndex, to: toIndex) {
            moveItem(fromInterval, from: fromIndex, to: toIndex)
        }
    }
    private func isValidMoveIndexes(from fromIndex: Int, to toIndex: Int) -> Bool {
        return isValidIndex(toIndex) &&
            fromIndex != toIndex
    }
    private func moveItem(_ interval: Interval,
                          from fromIndex: Int,
                          to toIndex: Int) {
        intervals.remove(at: fromIndex)
        intervals.insert(interval, at: toIndex)
        listener?.itemMoved(from: fromIndex, to: toIndex)
    }
}
