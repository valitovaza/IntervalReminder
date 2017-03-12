import XCTest
@testable import IntervalReminder
class IntervalsViewControllerTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let testRow: Int = 43
    
    // MARK: - Test variables
    private var sut: IntervalsViewController!
    private var presenter: MockIntervalPresenter!
    private var intervalPresenter: IntervalPresenter!
    private var interactor: MockInteractor!
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        createVariables()
    }
    private func createVariables() {
        presenter = MockIntervalPresenter()
        initViewController()
        initPresenter()
        sut.mainWindowContainer = MockMainWindowContainer()
    }
    private func initViewController() {
        sut = loadVc()
        interactor = getInteractor()
        sut.interactor = interactor
        _ = sut.view
    }
    private func loadVc() -> IntervalsViewController {
        return ViewControllersFactory.instantiateViewController(inStoryboard: .main) as IntervalsViewController
    }
    private func initPresenter() {
        intervalPresenter = sut.presenter as? IntervalPresenter
        sut.presenter = presenter
    }
    override func tearDown() {
        clearVariables()
        super.tearDown()
    }
    private func clearVariables() {
        presenter = nil
        intervalPresenter = nil
        sut = nil
    }
    
    // MARK: - Tests
    func testTableViewMustNotBeNil() {
        XCTAssertNotNil(sut.tableView)
    }
    func testButtonsMustNotBeNil() {
        XCTAssertNotNil(sut.intervalButton)
        XCTAssertNotNil(sut.stopButton)
        XCTAssertNotNil(sut.createButton)
    }
    func testCheckButtonExist() {
        XCTAssertNotNil(sut.checkButton)
    }
    func testCheckButtonsActionMustNotBeNil() {
        XCTAssertEqual(sut.checkButton.action, #selector(sut.changeRepeat(_:)))
    }
    func testCreateActionMustBeConfigured() {
        XCTAssertEqual(sut.createButton.action, #selector(sut.create(_:)))
    }
    func testStopButtonsInitialStateIsDisabled() {
        XCTAssertFalse(sut.stopButton.isEnabled)
    }
    func testPresenterInitialized() {
        XCTAssertNotNil(sut.presenter)
    }
    func testDataSourceMethodShouldBeDrivenByPresenter() {
        XCTAssertEqual(sut.numberOfRows(in: sut.tableView), presenter.count())
    }
    func testViewForRowMustBeCalledWithProperParameters() {
        let cell = sut.tableView(sut.tableView, viewFor: nil, row: testRow)
        XCTAssertEqual(cell, presenter.tableViewCell)
        XCTAssertEqual(presenter.atRow, testRow)
    }
    func testInteractorNotNilAfterViewDidLoad() {
        XCTAssertNotNil(sut.interactor)
    }
    func testPresentersDataProviderInitialized() {
        let sut = loadVc()
        XCTAssertNotNil((sut.presenter as! IntervalPresenter).dataProvider)
    }
    func testAddRowAtIndexPathMustInsertTableViewRow() {
        let table = mockTableView()
        sut.addRow(at: 0)
        XCTAssertTrue(table.reloadDataGotInvoked)
    }
    private var mockMainWindow: MockWindow {
        return sut.mainWindowContainer.mainWindow as! MockWindow
    }
    func testCreateShouldOpenModalWindow() {
        sut.create(NSButton())
        XCTAssertTrue(mockMainWindow.mockSheetWindow?.windowController is ModalController)
        XCTAssertNotNil(sut.createController)
    }
    func testModalControllerShouldOpenWithInteractor() {
        sut.create(NSButton())
        let modal = mockMainWindow.mockSheetWindow?.windowController as! ModalController
        XCTAssertNotNil(modal.intervalInteractor)
        XCTAssertNotNil(mockMainWindow.mockCompletionHandler)
    }
    func testSheetCompletitionHandlerMustRemoveCreateController() {
        sut.create(NSButton())
        sut.sheetHandler(0)
        XCTAssertNil(sut.createController)
    }
    func testTableViewClassIsIntervalTableView() {
        XCTAssertTrue(sut.tableView is IntervalTableView)
    }
    func testRemoveAtMustInvokeTableViewsRemoveRows() {
        let table = mockTableView()
        sut.removeRow(at: 0)
        XCTAssertTrue(table.reloadDataGotInvoked)
    }
    func testIntervalButtonsActionNotNil() {
        XCTAssertEqual(sut.intervalButton.action, #selector(sut.intervalAction(_:)))
    }
    func testStopButtonsActionNotNil() {
        XCTAssertEqual(sut.stopButton.action, #selector(sut.stop(_:)))
    }
    func testIntervalActionMustInvokeInteractor() {
        sut.intervalAction(NSButton())
        XCTAssertTrue(interactor.intervalActionGotInvoked)
    }
    func testStopMustInvokeInteractorsStop() {
        sut.stop(NSButton())
        XCTAssertTrue(interactor.stopGotInvoked)
    }
    private func getInteractor() -> MockInteractor {
        let mockInteractor = MockInteractor()
        sut.interactor = mockInteractor
        return mockInteractor
    }
    func testUpdateRowMustReloadTable() {
        let table = mockTableView()
        sut.updateRow(at: 0)
        XCTAssertTrue(table.reloadDataGotInvoked)
    }
    private func mockTableView() -> MockTableView {
        let mock = MockTableView()
        sut.tableView = mock
        return mock
    }
    func testChangeRepeatMustInvokeInteractor() {
        sut.changeRepeat(NSButton())
        XCTAssertTrue(interactor.changeRepeatGotInvoked)
    }
    func testReloadMustInvokeTableReload() {
        let table = mockTableView()
        sut.reload()
        XCTAssertTrue(table.reloadDataGotInvoked)
    }
    func testViewDidLoadMustCallFetch() {
        sut.viewDidLoad()
        XCTAssertTrue(interactor.fetchWasCalled)
    }
}
extension IntervalsViewControllerTests {
    class MockInteractor: IntervalInteractorProtocol {
        var intervalActionGotInvoked = false
        func intervalAction() {
            intervalActionGotInvoked = true
        }
        var changeRepeatGotInvoked = false
        func changeRepeat() {
            changeRepeatGotInvoked = true
        }
        var stopGotInvoked = false
        func stop() {
            stopGotInvoked = true
        }
        func create(interval: Double, withText text: String) {}
        var fetchWasCalled = false
        func fetch() {
            fetchWasCalled = true
        }
    }
    class MockTableView: NSTableView {
        var reloadDataGotInvoked = false
        override func reloadData() {
            reloadDataGotInvoked = true
        }
    }
    class MockIntervalPresenter: IntervalPresenterProtocol {
        var cnt = 456
        func count() -> Int {
            return cnt
        }
        var tableViewCell: NSTableCellView!
        var atRow: Int = -103
        func present(cell: NSTableCellView, at row: Int) {
            tableViewCell = cell
            atRow = row
        }
    }
    class MockWindow: NSWindow {
        var mockSheetWindow: NSWindow?
        var mockCompletionHandler: ((NSModalResponse) -> Swift.Void)?
        override func beginSheet(_ sheetWindow: NSWindow, completionHandler handler: ((NSModalResponse) -> Swift.Void)? = nil) {
            mockSheetWindow = sheetWindow
            mockCompletionHandler = handler
        }
    }
    class MockMainWindowContainer: MainWindowContainer {
        var mainWindow: NSWindow? = MockWindow()
    }
}
