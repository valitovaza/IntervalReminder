import XCTest
@testable import IntervalReminder
class ModalControllerTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let text = "test"
    
    // MARK: - Test variables
    private var sut: ModalController!
    private var interactor: MockInteractor!
    private var parent: MockWindow!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        createVariables()
    }
    private func createVariables() {
        initSut()
        initInteractor()
        initSheetChild()
    }
    private func initSut() {
        sut = ModalController.fromNib()
        sut.loadWindow()
        sut.windowDidLoad()
    }
    private func initInteractor() {
        interactor = MockInteractor()
        sut.intervalInteractor = interactor
    }
    private func initSheetChild() {
        let mock = MockSheetChild()
        parent = mock.sheetParent as! MockWindow
        sut.sheetChild = mock
    }
    override func tearDown() {
        clearVariables()
        super.tearDown()
    }
    private func clearVariables() {
        sut = nil
        interactor = nil
        parent = nil
    }
    
    // MARK: - Tests
    func testCanCreate() {
        XCTAssertNotNil(sut)
    }
    func testButtonsExist() {
        XCTAssertNotNil(sut.createButton)
        XCTAssertNotNil(sut.cancelButton)
    }
    func testControlsExist() {
        XCTAssertNotNil(sut.notificationTextField)
        XCTAssertNotNil(sut.intervalPicker)
    }
    func testTextsForBinding() {
        XCTAssertFalse(sut.createButton.isEnabled)
        XCTAssertEqual(sut.text, "")
        XCTAssertEqual(sut.trimmedText, "")
    }
    func testChangeTextLeadsToChangingTrimmedText() {
        sut.text = " "
        XCTAssertEqual(sut.trimmedText, "")
        sut.text = " \(text) " as NSString
        XCTAssertEqual(sut.trimmedText as String, text)
    }
    func testCancelButtonsActionMustBeNotNil() {
        XCTAssertEqual(sut.cancelButton.action, #selector(sut.cancel(_:)))
    }
    func testSheetChildWindowInitiated() {
        XCTAssertNotNil(sut.sheetChild)
    }
    func testCancelShouldInvokeParentsEndSheet() {
        sut.cancel(NSButton())
        XCTAssertEqual(parent.mockReturnCode , NSModalResponseCancel)
        XCTAssertNotNil(parent.mockSheetWindow)
    }
    func testCreateButtonActionMustBeNotNil() {
        XCTAssertEqual(sut.createButton.action, #selector(sut.create(_:)))
    }
    func testCreateActionMustInvokeInteractorsCreate() {
        sut.text = text as NSString
        sut.create(NSButton())
        XCTAssertEqual(interactor.mText, text)
        XCTAssertEqual(interactor.mInterval, 1200)
    }
    private var testDate: Date {
        let cal = Calendar.current
        return cal.date(from: testComponents(cal))!
    }
    private func testComponents(_ cal: Calendar) -> DateComponents {
        var components = dateComponents(cal)
        components.hour = 1
        components.minute = 3
        components.second = 45
        return components
    }
    private func dateComponents(_ cal: Calendar) -> DateComponents {
        let comp: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        return cal.dateComponents(comp, from: Date())
    }
    func testIntervalMustBeProvidedFromDatePicker() {
        sut.intervalPicker.dateValue = testDate
        sut.create(NSButton())
        XCTAssertEqual(interactor.mInterval, 3825)
    }
    func testCreateShouldInvokeParentEndSheet() {
        sut.create(NSButton())
        XCTAssertEqual(parent.mockReturnCode , NSModalResponseOK)
        XCTAssertNotNil(parent.mockSheetWindow)
    }
    func testSelectedDateMustChangeSelectedInterval() {
        sut.selectedDate = testDate
        XCTAssertEqual(sut.selectedIntervals, 3825)
    }
    func testZeroSelectedIntervalMustClearTrimmedText() {
        sut.setValue(text, forKey: "trimmedText")
        sut.selectedIntervals = 0
        XCTAssertEqual(sut.trimmedText, "")
    }
    func testInitialSelectedIntervalMustRelateToDefaultDate() {
        XCTAssertEqual(sut.selectedIntervals, 1200)
    }
    func testGreaterThanZeroSelectedIntervalMustSetTrimmedTextEqualToTextField() {
        sut.setValue(text, forKey: "text")
        XCTAssertEqual(sut.trimmedText as String, text)
        sut.selectedIntervals = 0
        XCTAssertEqual(sut.trimmedText, "")
        sut.selectedIntervals = 1
        XCTAssertEqual(sut.trimmedText as String, text)
    }
    func testTextCannotChangeTrimmedTextIfSelectedIntervalIsZero() {
        sut.selectedIntervals = 0
        sut.setValue(text, forKey: "text")
        XCTAssertEqual(sut.trimmedText, "")
    }
}
extension ModalControllerTests {
    class MockInteractor: IntervalInteractorProtocol {
        var mInterval: Double?
        var mText: String?
        func create(interval: Double, withText text: String) {
            mInterval = interval
            mText = text
        }
        func intervalAction() {}
        func changeRepeat() {}
        func stop() {}
        func fetch() {}
    }
    class MockSheetChild: SheetChildWindow {
        var sheetParent: NSWindow? = MockWindow()
    }
    class MockWindow: NSWindow {
        var mockSheetWindow: NSWindow?
        var mockReturnCode: Int?
        override func endSheet(_ sheetWindow: NSWindow, returnCode: NSModalResponse) {
            mockSheetWindow = sheetWindow
            mockReturnCode = returnCode
        }
    }
}
