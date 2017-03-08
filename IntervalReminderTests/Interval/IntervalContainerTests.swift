import XCTest
@testable import IntervalReminder
class IntervalContainerTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let timerInterval: Double = 23.342
    private let timerText = "TestString3123213123"
    private var testInterval: Interval {
        return Interval(timerInterval, timerText)
    }
    private var secondTestInterval: Interval {
        return Interval(12.231, "Tst22")
    }
    
    // MARK: - Test variables
    private var sut: IntervalContainer!
    private var listener: MockListener!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        listener = MockListener()
        sut = IntervalContainer(listener)
    }
    override func tearDown() {
        sut = nil
        listener = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testCanCreate() {
        XCTAssertNotNil(sut, "SUT must not be nil")
        XCTAssertNotNil(IntervalContainer(),
                        "SUT can be created without listener")
    }
    func testInitialEmptyState() {
        XCTAssertEqual(sut.intervalsCount, 0,
                       "Intervals count must be 0 when init state")
    }
    func testAddIntervalIncrementsCount() {
        sut.add(testInterval)
        XCTAssertEqual(sut.intervalsCount, 1,
                       "Intervals count must be 1 after add 1")
    }
    func testRemoveIntervalAfterAdded1() {
        sut.add(testInterval)
        sut.remove(at: 0)
        XCTAssertEqual(sut.intervalsCount, 0,
                       "Intervals count must be 0 after remove")
    }
    func testNewAddedIntervalAtTheTop() {
        add2Intervals(sut)
        XCTAssertEqual(sut.interval(at: 0), secondTestInterval,
                       "Top interval position must be 0")
        XCTAssertEqual(sut.interval(at: 1), testInterval,
                       "Second interval position must be 1")
    }
    func testReturnNilAtInvalidIndex() {
        XCTAssertNil(sut.interval(at: 0),
                     "Empty container should return nil at 0")
        XCTAssertNil(sut.interval(at: -1),
                     "Container should return nil at invalid index")
    }
    func testRemovesAfterAdds() {
        add2Intervals(sut)
        XCTAssertEqual(sut.intervalsCount, 2)
        sut.remove(at: 0)
        XCTAssertEqual(sut.intervalsCount, 1)
        sut.remove(at: 0)
        XCTAssertEqual(sut.intervalsCount, 0)
    }
    private func add2Intervals(_ sut: IntervalContainer) {
        sut.add(testInterval)
        sut.add(secondTestInterval)
    }
    func testInitialRemove_NotCrash() {
        sut.remove(at: 0)
    }
    func testRemoveAtInvalidIndex_NotCrash() {
        sut.add(testInterval)
        sut.remove(at: 2)
        sut.remove(at: 100)
        sut.remove(at: -1)
        sut.remove(at: -100)
    }
    func testMoveIntervals() {
        add2Intervals(sut)
        let thirdInterval = Interval(33.333, "Tst333")
        sut.add(thirdInterval)
        sut.move(from: 0, to: 1)
        checkMoveTest(sut, thirdInterval)
    }
    private func checkMoveTest(_ sut: IntervalContainer, _ thirdInterval: Interval) {
        XCTAssertEqual(sut.interval(at: 0), secondTestInterval,
                       "Index should changed after move")
        XCTAssertEqual(sut.interval(at: 1), thirdInterval,
                       "ThirdInterval's index should changed after move")
    }
    func testBoundaryMove() {
        add2Intervals(sut)
        XCTAssertEqual(sut.interval(at: 0), secondTestInterval,
                       "Item at index 0 before move == secondTestInterval")
        sut.move(from: 0, to: 1)
        XCTAssertEqual(sut.interval(at: 0), testInterval,
                       "Index should changed after move")
    }
    func testMoveToInvalidIndex() {
        add2Intervals(sut)
        sut.move(from: 0, to: 100)
        XCTAssertEqual(sut.interval(at: 0), secondTestInterval,
                       "Move to invalid index should be ignored")
        sut.move(from: 0, to: -100)
        XCTAssertEqual(sut.interval(at: 0), secondTestInterval,
                       "Move to invalid index should be ignored")
    }
    func testMoveToInvalidBoundary() {
        add2Intervals(sut)
        sut.move(from: 0, to: 2)
        XCTAssertEqual(sut.interval(at: 0), secondTestInterval,
                       "Move to invalid index should be ignored")
    }
    func testListenerItemAdded() {
        sut.add(testInterval)
        XCTAssertTrue(listener.itemAddedGotCalled,
                      "Listener's item added must be called")
    }
    func testListenerItemRemoved() {
        add2Intervals(sut)
        let deleteIndex = 1
        sut.remove(at: deleteIndex)
        XCTAssertEqual(listener.removedIndex, deleteIndex,
                       "Listener's item removed must be called")
    }
    func testListenerItemRemovedAtInvalidIndex() {
        sut.remove(at: 0)
        XCTAssertNil(listener.removedIndex,
                     "Item remove must not be called at invalid index")
        sut.remove(at: -10)
        XCTAssertNil(listener.removedIndex,
                     "Item remove must not be called at invalid index")
    }
    func testListenerMove() {
        add2Intervals(sut)
        sut.move(from: 0, to: 1)
        XCTAssertEqual(listener.fromIndex, 0,
                       "From index should be equal to provided")
        XCTAssertEqual(listener.toIndex, 1,
                       "To index should be equal to provided")
    }
    func testMoveEqualToAndFromIndexes() {
        add2Intervals(sut)
        sut.move(from: 0, to: 0)
        XCTAssertNil(listener.fromIndex,
                     "Move with equal indexes should be ignored")
        XCTAssertNil(listener.toIndex,
                     "Move with equal indexes should be ignored")
    }
    func testItemMovedShouldNotLeadToItemDeletedAndItemAdded() {
        add2Intervals(sut)
        sut.move(from: 0, to: 1)
        XCTAssertNil(listener.removedIndex,
                     "Item move should not lead to item remove delegate method")
    }
}
extension IntervalContainerTests {
    class MockListener: ContainerListener {
        var itemAddedGotCalled = false
        func itemAdded() {
            itemAddedGotCalled = true
        }
        var removedIndex: Int? = nil
        func itemRemoved(at index: Int) {
            removedIndex = index
        }
        var fromIndex: Int? = nil
        var toIndex: Int? = nil
        func itemMoved(from fromIndex: Int, to toIndex: Int) {
            self.fromIndex = fromIndex
            self.toIndex = toIndex
        }
    }
}
