import XCTest
@testable import IntervalReminder
class IntervalTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let timeInterval: Double = 4.4523
    private let timeText = "TestString214414"
    
    // MARK: - Test variables
    private var sut: Interval!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        sut = Interval(timeInterval, timeText)
    }
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testCanCreateInterval() {
        XCTAssertNotNil(sut, "SUT must not be nil")
    }
    func testInitialTimeIntervalField() {
        XCTAssertEqual(sut.timeInterval, timeInterval,
                       "TimerInterval must be set from the provided data")
    }
    func testInitialTimeTextField() {
        XCTAssertEqual(sut.text, timeText,
                       "Text must be set from the provided data")
    }
    
    // MARK: - Equatable
    func testInstanceIsEqualToItself() {
        XCTAssertEqual(sut, sut,
                       "A Speaker instance must be equal to itself")
    }
    func testInstanceIsDifferentIfTimeIntervalIsDifferent() {
        XCTAssertNotEqual(sut, Interval(3.44545, timeText),
                          "Speaker instances must be different if the timeInterval is different")
    }
    func testInstanceIsDifferentIfTextIsDifferent() {
        XCTAssertNotEqual(sut, Interval(timeInterval, "TestText"),
                          "Speaker instances must be different if the text is different")
    }
}
