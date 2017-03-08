import XCTest
@testable import IntervalReminder
class StatusBarManagerTests: XCTestCase {
    // MARK: - Test variables
    private var sut: StatusBarManager!
    private var app: MockActivatable!
    private var nc: MockNotificationCenter!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        createVariables()
    }
    override func tearDown() {
        clearVariables()
        super.tearDown()
    }
    private func createVariables() {
        sut = StatusBarManager()
        app = MockActivatable()
        nc = MockNotificationCenter()
        sut.activatable = app
        sut.notificationCenter = nc
    }
    private func clearVariables() {
        sut = nil
        app = nil
        nc = nil
    }
    
    // MARK: - Tests
    func testSutIsntNil() {
        XCTAssertNotNil(sut, "SUT must not be nil.")
    }
    func testStatusItemIsDefinedInInit() {
        XCTAssertNotNil(sut.statusItem,
                        "StatusItem must not be nil.")
        XCTAssertEqual(sut.statusItem.length, -2,
                       "Make sure the hack -2")
    }
    func testActivateInvokedInConfigure() {
        sut.configure()
        XCTAssertTrue(app.activateFlagGotSetted!,
                      "Activate should be invoked in configure")
    }
    func testStatusBarButtonHasImage() {
        sut.configure()
        XCTAssertNotNil(sut.statusItem.button!.image,
                       "Status bar has image")
    }
    func testMenuIsConfigured() {
        sut.configure()
        let menu = sut.statusItem.menu
        XCTAssertNotNil(menu, "Menu must not be nil")
        tstInitialItems(menu!)
    }
    private func tstInitialItems(_ menu: NSMenu) {
        tstItem(menu, 0, MenuTitles.Start.value)
        tstItem(menu, 2, MenuTitles.Show.value)
        tstItem(menu, 3, MenuTitles.Quit.value)
    }
    private func tstItem(_ menu: NSMenu, _ index: Int, _ expectedTitle: String) {
        XCTAssertEqual(menu.items[index].title, expectedTitle)
        XCTAssertEqual(menu.items[index].keyEquivalent, "")
        XCTAssertNotNil(menu.items[index].target)
    }
    func testInitialMenuActionsConfigured() {
        sut.configure()
        let menu = sut.statusItem.menu!
        tstInitialActions(menu)
    }
    private func tstInitialActions(_ menu: NSMenu) {
        XCTAssertEqual(menu.items[0].action, #selector(sut.start(sender:)))
        XCTAssertEqual(menu.items[2].action, #selector(sut.show(sender:)))
        XCTAssertEqual(menu.items[3].action, #selector(sut.quit(sender:)))
    }
    func testMenuAfterStart() {
        sut.configure()
        NotificationCenter.default.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        tstInProgressItems(sut.statusItem.menu!)
        tstInProgressActions(sut.statusItem.menu!)
    }
    private func tstInProgressItems(_ menu: NSMenu) {
        tstItem(menu, 0, MenuTitles.Pause.value)
        tstItem(menu, 1, MenuTitles.Stop.value)
        tstItem(menu, 3, MenuTitles.Show.value)
        tstItem(menu, 4, MenuTitles.Quit.value)
    }
    private func tstInProgressActions(_ menu: NSMenu) {
        XCTAssertEqual(menu.items[0].action, #selector(sut.pause(sender:)))
        XCTAssertEqual(menu.items[1].action, #selector(sut.stop(sender:)))
    }
    func testMenuAfterStop() {
        sut.configure()
        NotificationCenter.default.post(Notification.Name.IntervalReminderNotifications.IntervalStopped.notification)
        tstStopItems(sut.statusItem.menu!)
        tstStopActions(sut.statusItem.menu!)
    }
    private func tstStopItems(_ menu: NSMenu) {
        tstItem(menu, 0, MenuTitles.Resume.value)
        tstItem(menu, 1, MenuTitles.Stop.value)
        tstItem(menu, 3, MenuTitles.Show.value)
        tstItem(menu, 4, MenuTitles.Quit.value)
    }
    private func tstStopActions(_ menu: NSMenu) {
        XCTAssertEqual(menu.items[0].action, #selector(sut.resume(sender:)))
        XCTAssertEqual(menu.items[1].action, #selector(sut.stop(sender:)))
    }
    func testMenuAfterResume() {
        sut.configure()
        NotificationCenter.default.post(Notification.Name.IntervalReminderNotifications.IntervalResumed.notification)
        tstInProgressItems(sut.statusItem.menu!)
        tstInProgressActions(sut.statusItem.menu!)
    }
    func testMenuAfterIntervalEnded() {
        sut.configure()
        NotificationCenter.default.post(Notification.Name.IntervalReminderNotifications.IntervalStarted.notification)
        NotificationCenter.default.post(Notification.Name.IntervalReminderNotifications.IntervalEnded.notification)
        tstInitialActions(sut.statusItem.menu!)
    }
    func testQuitMustCallTerminate() {
        sut.quit(sender: NSMenuItem())
        XCTAssertNotNil(app.terminateSender,
                        "NSApp terminate should be called in quit")
    }
    func testShowMustCallActivate() {
        sut.show(sender: NSMenuItem())
        XCTAssertTrue(app.activateFlagGotSetted!,
                      "Activate should be invoked in show")
    }
    func testMakeKeyAndOrderFrontGotInvokedInShow() {
        let mockWindow = MockWindow()
        app.windows.append(mockWindow)
        sut.show(sender: NSMenuItem())
        XCTAssertTrue(mockWindow.makeKeyAndOrderFrontGotInvoked!,
                      "MakeKeyAndOrderFront got invoked in show")
    }
    func testNotificationPostedInStart() {
        sut.start(sender: NSMenuItem())
        XCTAssertEqual(nc.postedNotification!.name, Notification.Name.IntervalReminderNotifications.StartFromStatusbar.name,
                       "Proper notification should be posted")
    }
    func testEventListenerShouldBeInitialized() {
        sut.configure()
        XCTAssertEqual(sut.repeaterListener.statusButton, sut.statusItem.button,
                       "Listener button should be setted from statusItem")
    }
    func testListenerDelegateNotNil() {
        sut.configure()
        XCTAssertNotNil(sut.repeaterListener.delegate,
                        "Listener delegate must be setted")
    }
    func testNotificationPostedWhenPause() {
        sut.pause(sender: NSMenuItem())
        XCTAssertEqual(nc.postedNotification!.name, Notification.Name.IntervalReminderNotifications.PauseFromStatusbar.name,
                       "PauseFromStatusbar notification should be posted")
    }
    func testNotificationPostedWhenResume() {
        sut.resume(sender: NSMenuItem())
        XCTAssertEqual(nc.postedNotification!.name, Notification.Name.IntervalReminderNotifications.ResumeFromStatusbar.name,
                       "ResumeFromStatusbar notification should be posted")
    }
    func testNotificationPostedWhenStop() {
        sut.stop(sender: NSMenuItem())
        XCTAssertEqual(nc.postedNotification!.name, Notification.Name.IntervalReminderNotifications.StopFromStatusbar.name,
                       "StopFromStatusbar notification should be posted")
    }
}
extension StatusBarManagerTests {
    class MockWindow: NSWindow {
        var makeKeyAndOrderFrontGotInvoked: Bool?
        override func makeKeyAndOrderFront(_ sender: Any?) {
            makeKeyAndOrderFrontGotInvoked = true
        }
    }
    class MockActivatable: Applicationable {
        var activateFlagGotSetted: Bool?
        func activate(ignoringOtherApps flag: Bool) {
            activateFlagGotSetted = flag
        }
        var terminateSender: Any?
        func terminate(_ sender: Any?) {
            terminateSender = sender
        }
        var windows: [NSWindow] = []
    }
    class MockNotificationCenter: NotificationCenterable {
        var postedNotification: Notification?
        func post(_ notification: Notification) {
            postedNotification = notification
        }
        func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol {
            return NSObject()
        }
        func removeObserver(_ observer: Any) {}
    }
}
