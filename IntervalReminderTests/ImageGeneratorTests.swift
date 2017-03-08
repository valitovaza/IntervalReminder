import XCTest
@testable import IntervalReminder
class ImageGeneratorTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let timeInterval: Double = 4.0
    private let pastTimeInterval: Double = 2.0
    
    // MARK: - Test variables
    private var sut: ImageGenerator!
    private var delegate: MockListener!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        createVariables()
    }
    private func createVariables() {
        delegate = MockListener()
        sut = ImageGenerator()
        sut.delegate = delegate
    }
    override func tearDown() {
        sut = nil
        delegate = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testSutIsntNil() {
        XCTAssertNotNil(sut, "SUT must not be nil.")
        XCTAssertEqual(sut.currentPercent, 0.0)
        XCTAssertEqual(sut.interval, 0.0)
        XCTAssertEqual(sut.pastInterval, 0.0)
    }
    func testGenerateShouldReturnImage() {
        XCTAssertNotNil(sut.generate(),
                        "Generated image must not be nil.")
    }
    func testImageSizeShouldBeProvided() {
        XCTAssertEqual(sut.generate().size,
                       CGSize(width: sut.imageSize, height: sut.imageSize),
                       "Image size should be equal to provided")
    }
    func testSetInterval() {
        sut.setInterval(timeInterval)
        XCTAssertEqual(sut.interval, timeInterval,
                       "interval must be equal to provided")
    }
    func testSetPastInterval() {
        sut.setPastInterval(pastTimeInterval)
        XCTAssertEqual(sut.pastInterval, pastTimeInterval,
                       "pastInterval must be equal to provided")
    }
    func testCurrentPercentMustBeRelatedToIntervalAndPastInterval() {
        sut.setInterval(timeInterval)
        sut.setPastInterval(pastTimeInterval)
        XCTAssertEqual(sut.currentPercent, 0.5)
        sut.setInterval(0.0)
        XCTAssertEqual(sut.currentPercent, 0.0)
    }
    func testDelegateGotCalled() {
        sut.setInterval(timeInterval)
        XCTAssertTrue(delegate.imageChangeGotCalled,
                      "Delegate got called in SetInterval")
    }
    func testDelegateGotCalledInSetPastInterval() {
        sut.setPastInterval(pastTimeInterval)
        XCTAssertTrue(delegate.imageChangeGotCalled,
                      "Delegate got called in SetPastInterval")
    }
    func testIncrementShouldInvokeDelegate() {
        sut.incrementInterval()
        XCTAssertTrue(delegate.imageChangeGotCalled,
                      "Delegate got called in IncrementInterval")
    }
    func testIncrementMustChangePastInterval() {
        sut.incrementInterval()
        XCTAssertEqual(sut.pastInterval, 1.0,
                       "Increment should change past interval")
    }
    func testIncrementMustChangePercent() {
        sut.setInterval(timeInterval)
        sut.incrementInterval()
        sut.incrementInterval()
        XCTAssertEqual(sut.currentPercent, 0.5,
                       "Increment must change interval percent")
    }
}
extension ImageGeneratorTests {
    class MockListener: ImageChangeListener {
        var imageChangeGotCalled = false
        func imageChanged(image: NSImage) {
            imageChangeGotCalled = true
        }
    }
}
