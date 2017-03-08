import XCTest
@testable import IntervalReminder
class IntervalTableViewTests: XCTestCase {
    // MARK: - Test variables
    private var sut: IntervalTableView!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        sut = IntervalTableView()
    }
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testCanCreate() {
        XCTAssertNotNil(sut, "SUT must not be nil")
    }
    func testReturnedMenu() {
        insert4Rows()
        XCTAssertNil(sut.menu(for: NSEvent()))
        selectFirstRow()
        XCTAssertNotNil(sut.menu(for: NSEvent()))
    }
    private func insert4Rows() {
        sut.beginUpdates()
        sut.insertRows(at: IndexSet(integersIn: 0..<4), withAnimation: .effectGap)
        sut.endUpdates()
    }
    private func selectFirstRow() {
        sut.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }
    func testDeleteActionMustPostNotification() {
        insert4Rows()
        selectFirstRow()
        let menu = sut.menu(for: NSEvent())!
        XCTAssertEqual(menu.items[0].action, #selector(sut.deleteInterval))
        XCTAssertEqual(menu.items[0].title, TableViewMenu.Delete.rawValue)
    }
    func testNotificationCenterInitialized() {
        XCTAssertNotNil(sut.notificationCenter)
    }
    func testDeleteIntervalMustPostProperNotification() {
        let mock = MockNotificationCenter()
        sut.notificationCenter = mock
        sut.deleteInterval()
        XCTAssertEqual(mock.mockNorification!.name,
                       Notification.Name.IntervalReminderNotifications.DeleteFromMenu.name)
        XCTAssertNotNil(mock.mockNorification?.userInfo?[IntervalReminderKeys.deleteIndex.value])
    }
}
extension IntervalTableViewTests {
    class MockNotificationCenter: NotificationCenterable {
        var mockNorification: Notification?
        func post(_ notification: Notification) {
            mockNorification = notification
        }
        func addObserver(forName name: NSNotification.Name?, object obj: Any?,
                         queue: OperationQueue?,
                         using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol {
            return NSObject()
        }
        func removeObserver(_ observer: Any) {}
    }
}
