import XCTest
@testable import IntervalReminder
class IntervalPresenterTests: XCTestCase {
    // MARK: - Parameters & Constants
    let testInterval: Double = 34
    let testRow = 40
    let deleteTestIndex = 45
    let testTitle = "Abracadabra"
    
    
    // MARK: - Test variables
    private var sut: IntervalPresenter!
    private var dataProvider: MockDataProvider!
    private var nc: MockNotificationCenter!
    private var wnc: MockNotificationCenter!
    private var view: MockView!
    private var cell: NSTableCellView!
    private var textField: NSTextField!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        createVariables()
    }
    private func createVariables() {
        view = MockView()
        nc = MockNotificationCenter()
        wnc = MockNotificationCenter()
        sut = IntervalPresenter(view, nc, wnc)
        initDataProvider()
        initViews()
    }
    private func initDataProvider() {
        dataProvider = MockDataProvider()
        sut.dataProvider = dataProvider
    }
    private func initViews() {
        cell = NSTableCellView()
        textField = NSTextField()
        cell.textField = textField
    }
    override func tearDown() {
        clearVariables()
        super.tearDown()
    }
    private func clearVariables() {
        sut = nil
        dataProvider = nil
        nc = nil
        view = nil
        cell = nil
        textField = nil
    }
    
    // MARK: - Tests
    func testCanBeCreated() {
        XCTAssertNotNil(sut)
    }
    func testCountReturnedFromDataProvider() {
        XCTAssertEqual(sut.count(), dataProvider.count())
    }
    func testCellsTextMustBeCreatedWithIntervalData() {
        sut.present(cell: cell, at: testRow)
        let expectedCellText = "\(dataProvider.title(forRow: testRow)) 03:26:02"
        XCTAssertEqual(textField.stringValue, expectedCellText)
    }
    func testCurrentCellsTextMustBeDifferent() {
        sut.present(cell: cell, at: dataProvider.currentIndex)
        let expectedCellText = "\(dataProvider.title(forRow: dataProvider.currentIndex)) 00:00:04 - 03:26:02"
        XCTAssertEqual(textField.stringValue, expectedCellText)
    }
    func testViewIsNotNil() {
        XCTAssertNotNil(sut.view)
    }
    func testNewIntervalMustLeadToAddRowAtIndexPath() {
        sut.newInterval(at: testRow)
        XCTAssertEqual(view.savedRow, testRow)
    }
    func testNotificationCenterInitialized() {
        XCTAssertNotNil(sut.notificationCenter)
    }
    func testObserversSettedInInit() {
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.StartFromStatusbar.name))
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.PauseFromStatusbar.name))
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.ResumeFromStatusbar.name))
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.StopFromStatusbar.name))
        XCTAssertTrue(nc.mockNames.contains(Notification.Name.IntervalReminderNotifications.DeleteFromMenu.name))
    }
    func testRemoveObserverShouldBeInvokedWhenDeinit() {
        sut = nil
        XCTAssertEqual(nc.mockObservers.count, 0,
                       "All observers must be removed")
    }
    func testDeleteNotificationMustInvokeDeleteInterval() {
        postDeleteNotification()
        XCTAssertEqual(dataProvider.deleteIndex, deleteTestIndex)
    }
    func testDeleteNotificationMustInvokeViewsRemove() {
        postDeleteNotification()
        XCTAssertEqual(view.removeIndex, deleteTestIndex)
    }
    private func postDeleteNotification() {
        let notification = Notification(name: Notification.Name.IntervalReminderNotifications.DeleteFromMenu.name, object: nil, userInfo: [IntervalReminderKeys.deleteIndex.value: deleteTestIndex])
        nc.post(notification)
    }
    func testStartFromStatusbarMustInvokeDataProvidersStart() {
        nc.post(Notification.Name.IntervalReminderNotifications.StartFromStatusbar.notification)
        XCTAssertTrue(dataProvider.startGotInvoked)
    }
    func testPauseFromStatusbarMustInvokeDataProvidersPause() {
        nc.post(Notification.Name.IntervalReminderNotifications.PauseFromStatusbar.notification)
        XCTAssertTrue(dataProvider.pauseGotInvoked)
    }
    func testResumeFromStatusbarMustInvokeDataProvidersResume() {
        nc.post(Notification.Name.IntervalReminderNotifications.ResumeFromStatusbar.notification)
        XCTAssertTrue(dataProvider.resumeGotInvoked)
    }
    func testStopFromStatusbarMustInvokeDataProvidersStop() {
        nc.post(Notification.Name.IntervalReminderNotifications.StopFromStatusbar.notification)
        XCTAssertTrue(dataProvider.stopGotInvoked)
    }
    func testEnableIntervalButton() {
        let btn = intervalButton()
        btn.isEnabled = false
        sut.enableIntervalButton()
        XCTAssertTrue(btn.isEnabled)
    }
    func testDisableIntervalButton() {
        let btn = intervalButton()
        btn.isEnabled = true
        btn.title = testTitle
        sut.disableIntervalButton()
        XCTAssertFalse(btn.isEnabled)
        XCTAssertEqual(btn.title, ButtonTitles.Start.rawValue)
    }
    private func intervalButton() -> NSButton {
        let btn = NSButton()
        view.intervalButton = btn
        return btn
    }
    func testConfigureIntervalButtonTitle() {
        let btn = intervalButton()
        sut.configureIntervalButton(title: testTitle)
        XCTAssertEqual(btn.title, testTitle)
    }
    func testConfigureStopButton() {
        let btn = stopButton()
        sut.configureStopButton(inProgress: false)
        XCTAssertFalse(btn.isEnabled)
        sut.configureStopButton(inProgress: true)
        XCTAssertTrue(btn.isEnabled)
    }
    private func stopButton() -> NSButton {
        let btn = NSButton()
        view.stopButton = btn
        return btn
    }
    func testUpdateProgressMustInvokeUpdateViewsRow() {
        sut.updateProgress()
        XCTAssertEqual(view.updateIndex, dataProvider.currentIndex)
    }
    func testIntervalStartedMustPostStartedNotification() {
        sut.intervalStarted(testInterval)
        XCTAssertEqual(nc.lastNotification?.name, Notification.Name.IntervalReminderNotifications.IntervalStarted.name)
        XCTAssertEqual(nc.lastNotification!.userInfo![IntervalReminderKeys.reminderInterval.rawValue] as! Double, testInterval)
    }
    func testIntervalStoppedMustPostNotification() {
        sut.intervalStopped()
        XCTAssertEqual(nc.lastNotification?.name, Notification.Name.IntervalReminderNotifications.IntervalStopped.name)
    }
    func testIntervalEndedMustPostNotification() {
        sut.intervalEnded()
        XCTAssertEqual(nc.lastNotification?.name, Notification.Name.IntervalReminderNotifications.IntervalEnded.name)
    }
    func testIntervalResumedMustPostNotification() {
        sut.intervalResumed(elapsed: 0.1, interval: testInterval)
        XCTAssertEqual(nc.lastNotification?.name, Notification.Name.IntervalReminderNotifications.IntervalResumed.name)
        XCTAssertEqual(nc.lastNotification!.userInfo![IntervalReminderKeys.reminderInterval.rawValue] as! Double, testInterval)
        XCTAssertEqual(nc.lastNotification!.userInfo![IntervalReminderKeys.reminderPastInterval.rawValue] as! Double, 0.1)
    }
    func testNSWorkspaceNotificationCenterSet() {
        XCTAssertNotNil(sut.workspaceNotificationCenter)
    }
    func testWorspaceNotificationCenterObservesNSWorkspaceWillSleepNotification() {
        XCTAssertEqual(wnc.mockNames[0], NSNotification.Name.NSWorkspaceWillSleep)
    }
    func testWorspaceObserversMustRemoveWhenDeinit() {
        sut = nil
        XCTAssertEqual(wnc.mockObservers.count, 0)
    }
    func testNSWorkspaceWillSleepNotificationMustLeadToPause() {
        wnc.post(Notification(name: NSNotification.Name.NSWorkspaceWillSleep))
        XCTAssertTrue(dataProvider.pauseGotInvoked)
    }
    func testReloadMustInvokeViewsReload() {
        let btn = intervalButton()
        btn.isEnabled = false
        dataProvider.cnt = 0
        sut.reload()
        XCTAssertTrue(view.reloadWasCalled)
        XCTAssertFalse(btn.isEnabled)
    }
    func testReloadMustEnableIntervalButtonIfCountGreaterThan0() {
        let btn = intervalButton()
        btn.isEnabled = false
        dataProvider.cnt = 1
        sut.reload()
        XCTAssertTrue(btn.isEnabled)
    }
    func testReloadMustDisableIntervalButtonIfCountIs0() {
        let btn = intervalButton()
        btn.isEnabled = true
        dataProvider.cnt = 0
        sut.reload()
        XCTAssertFalse(btn.isEnabled)
    }
    func testNotificationCenterObservesNSApplicationWillTerminate() {
        XCTAssertTrue(nc.mockNames.contains(NSNotification.Name.NSApplicationWillTerminate))
    }
    func testNSApplicationWillTerminateMustInvokeSaveIntervals() {
        nc.post(Notification(name: NSNotification.Name.NSApplicationWillTerminate))
        XCTAssertTrue(dataProvider.saveIntervalsWasCalled)
    }
}
extension IntervalPresenterTests {
    class MockNotificationCenter: NotificationCenterable {
        var nitificationsToActions: [NSNotification.Name: ((Notification) -> Swift.Void)] = [:]
        var lastNotification: Notification?
        func post(_ notification: Notification) {
            lastNotification = notification
            nitificationsToActions[notification.name]?(notification)
        }
        var mockNames: [Notification.Name] = []
        var mockObservers: [NSObjectProtocol] = []
        func addObserver(forName name: NSNotification.Name?,
                         object obj: Any?, queue: OperationQueue?,
                         using block: @escaping (Notification) -> Swift.Void) -> NSObjectProtocol {
            nitificationsToActions[name!] = block
            mockNames.append(name!)
            let observer = NSObject()
            mockObservers.append(observer)
            return observer
        }
        func removeObserver(_ observer: Any) {
            if let obs = observer as? NSObjectProtocol {
                deleteIfContained(obs)
            }
        }
        private func deleteIfContained(_ obs: NSObjectProtocol) {
            for index in 0..<mockObservers.count {
                if mockObservers[index].isEqual(obs) {
                    mockObservers.remove(at: index)
                    break
                }
            }
        }
    }
    class MockView: IntervalsViewProtocol {
        weak var intervalButton: NSButton!
        weak var stopButton: NSButton!
        weak var createButton: NSButton!
        var savedRow: Int?
        func addRow(at index: Int) {
            savedRow = index
        }
        var removeIndex: Int?
        func removeRow(at index: Int) {
            removeIndex = index
        }
        var updateIndex: Int?
        func updateRow(at index: Int) {
            updateIndex = index
        }
        var reloadWasCalled = false
        func reload() {
            reloadWasCalled = true
        }
    }
    class MockDataProvider: IntervalDataProvider {
        // MARK: - Parameters & Constants
        let testHours = 3.0
        let testMins = 26.0
        let testSec = 2.0
        let secInHour = 60.0 * 60.0
        let minInHour = 60.0
        var currentIndex = 10
        
        //MARK: - IntervalDataProvider
        var cnt = 45
        func count() -> Int {
            return cnt
        }
        func elapsedInterval(forRow row: Int) -> Double {
            return 4.0
        }
        func title(forRow row: Int) -> String{
            return "test\(row)"
        }
        func interval(forRow row: Int) -> Double {
            return testHours * secInHour + testMins * minInHour + testSec
        }
        var deleteIndex: Int?
        func delete(at index: Int) {
            deleteIndex = index
        }
        var startGotInvoked = false
        func start() {
            startGotInvoked = true
        }
        var pauseGotInvoked = false
        func pause() {
            pauseGotInvoked = true
        }
        var resumeGotInvoked = false
        func resume() {
            resumeGotInvoked = true
        }
        var stopGotInvoked = false
        func stop() {
            stopGotInvoked = true
        }
        var saveIntervalsWasCalled = false
        func saveIntervals() {
            saveIntervalsWasCalled = true
        }
    }
}
