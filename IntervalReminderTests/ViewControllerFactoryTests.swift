import XCTest
@testable import IntervalReminder
class ViewControllerFactoryTests: XCTestCase {
    func testInstantiateViewControllerMustReturnViewController() {
        let vc: IntervalsViewController = ViewControllersFactory.instantiateViewController(inStoryboard: .main)
        XCTAssertNotNil(vc)
    }
}
