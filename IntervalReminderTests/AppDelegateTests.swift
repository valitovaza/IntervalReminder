import XCTest
@testable import IntervalReminder
class AppDelegateTests: XCTestCase {
    // MARK: - Test variables
    private var sut: AppDelegate!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        sut = AppDelegate()
    }
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testHasConfigurator() {
        XCTAssertNotNil(sut.configurator)
    }
    func testTheAppWasConfiguredInApplicationDidFinishLaunching() {
        let mock = MockConfigurator()
        sut.configurator = mock
        sut.applicationDidFinishLaunching(Notification(name: NSNotification.Name.NSApplicationDidFinishLaunching))
        XCTAssertTrue(mock.configureWasInvoked)
    }
}
extension AppDelegateTests {
    class MockConfigurator: Configurator{
        var configureWasInvoked = false
        func configure() {
            configureWasInvoked = true
        }
    }
}
