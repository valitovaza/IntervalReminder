import XCTest
@testable import IntervalReminder
class AppConfiguratorTests: XCTestCase {
    // MARK: - Test variables
    private var sut: AppConfigurator!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        sut = AppConfigurator()
    }
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testSutIsntNil() {
        XCTAssertNotNil(sut, "SUT must not be nil.")
    }
    func testStatusBarManagerIsDefinedInInit() {
        XCTAssertNotNil(sut.statusBarManager,
                        "StatusBarManager must not be nil.")
    }
    func testStatusBarConfigureWillInvoke() {
        let mock = MockStatusBarManager()
        sut.statusBarManager = mock
        sut.configure()
        XCTAssertTrue(mock.isConfigureInvoked,
                      "StatusBar configure method invoked in configure method")
    }
}
extension AppConfiguratorTests {
    class MockStatusBarManager: StatusBarManager {
        var isConfigureInvoked = false
        override func configure() {
            isConfigureInvoked = true
        }
    }
}
