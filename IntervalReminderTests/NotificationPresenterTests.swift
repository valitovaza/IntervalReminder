import XCTest
@testable import IntervalReminder
class NotificationPresenterTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let timerText = "TestString3123213123"
    
    // MARK: - Test variables
    private var sut: NotificationPresenter!
    private var deliverer: MockDeliverer!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        deliverer = MockDeliverer()
        sut = NotificationPresenter(deliverer: deliverer)
    }
    override func tearDown() {
        sut = nil
        deliverer = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testCanCreate() {
        XCTAssertNotNil(sut, "SUT must not be nil")
    }
    func testDelivererMustNotBeNil() {
        XCTAssertNotNil(sut.deliverer)
    }
    func testPresentNotificationMustDeliverNotification() {
        sut.presentNotification(timerText)
        XCTAssertEqual(deliverer.notification?.title, "IntervalReminder")
        XCTAssertEqual(deliverer.notification?.informativeText, timerText)
    }
    func testDelivererDelegateSetBeforeDeliver() {
        sut.presentNotification("")
        XCTAssertNotNil(deliverer.delegateBeforeNotification)
    }
    func testShouldPresentNotificationReturnTrue() {
        XCTAssertTrue(sut.userNotificationCenter(NSUserNotificationCenter.default,
                                                 shouldPresent: NSUserNotification()))
    }
}
extension NotificationPresenterTests {
    class MockDeliverer: NotificationDeliverer {
        var delegate: NSUserNotificationCenterDelegate?
        var notification: NSUserNotification?
        var delegateBeforeNotification: NSUserNotificationCenterDelegate?
        func deliver(_ notification: NSUserNotification) {
            delegateBeforeNotification = self.delegate
            self.notification = notification
        }
    }
}
